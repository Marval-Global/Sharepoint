BuildRequest
<%@ WebHandler Language="C#" Class="ApiHandler" %>

using System;

using System.IO;
using System.Net;
using System.Xml;
using System.Linq;
using System.Xml.Linq;
using Newtonsoft.Json.Linq;
using System.Reflection;
using System.Xml.Serialization;
using System.Collections;
using System.Net.Http.Headers;

using System.Collections.Generic;
using System.Text;
using MarvalSoftware.ServiceDesk.ServiceDelivery.AvailabilityManagement;
using System.Threading;
using System.Threading.Tasks;
using Serilog;
using System.Web.Script.Serialization;
using MarvalSoftware.Data.ServiceDesk;
using MarvalSoftware.Data.ServiceDesk.Rules;
using System.Web;
using MarvalSoftware.Rules;
using MarvalSoftware.ServiceDesk.Facade;
using MarvalSoftware.Predicates;
using MarvalSoftware.ServiceDesk.Facade.Rules.RuleActions;
using MarvalSoftware.DataTransferObjects.IntegrationMessages;
using MarvalSoftware.ServiceDesk.Facade.Rules.RuleObjects;
using MarvalSoftware.DataTransferObjects;
using MarvalSoftware.DataTransferObjects.Rules;
using MarvalSoftware;
using MarvalSoftware.UI.WebUI.ServiceDesk.RFP.Plugins;
using MarvalSoftware.UI.WebUI.ServiceDesk.RFP.Forms;
using System.Net.Http;
using Newtonsoft.Json;
using MarvalSoftware.Data;

/// <summary>
/// ApiHandler
/// </summary>
public class ApiHandler : PluginHandler
{
    private ServiceDeskFacade serviceDeskFacade = new ServiceDeskFacade();
    private RuleSetBroker rulesetBroker = new RuleSetBroker();
    private ActionMessageBroker actionMessageCreate = new ActionMessageBroker();
    //private static readonly HttpClient httpClient = new HttpClient();
    //properties
    private string UserAPIKey
    {
        get
        {
            return GlobalSettings["@@UserAPIKey"];
        }
    }

    private string APPToken
    {
        get
        {
            return GlobalSettings["@@APPToken"];
        }
    }

    public class RequestData
    {
        public string Message { get; set; }
        public string PhoneTo { get; set; }
        public string action { get; set; }
        public string encryptString { get; set; }
        public string actionMessageText { get; set; }

        public string actionMessageURL { get; set; }
        public int actionMessageId { get; set; }
        public int WorkflowId { get; set; }

        public int WorkflowStatusId { get; set; }

        public string email { get; set; }
        public string mailNickname { get; set; }
        public string Firstname { get; set; }
        public string Lastname { get; set; }
        public string fullName { get; set; }
        public string requestId { get; set; }

    }



    private string BaseUrl
    {
        get
        {
            return "https://api.pushover.net/1/messages.json";
        }
    }



    public class fullResponse
    {
        public int responseCode { get; set; }//res code
        public string responseDes { get; set; } //res desc
        public string responseBody { get; set; } //res body
    }

    /// <summary>
    /// Handle Request
    /// </summary>
    public override void HandleRequest(HttpContext context)
    {
        var action = context.Request.QueryString["action"];
        RouteRequest(action, context);
    }

    public override bool IsReusable
    {
        get { return false; }
    }



    /// <summary>
    /// Get request body value.
    /// </summary>
    /// <returns>Body value</returns>
    private string GetPostRequestData()
    {
        var streamReader = new StreamReader(HttpContext.Current.Request.InputStream);
        streamReader.BaseStream.Seek(0, SeekOrigin.Begin);
        return streamReader.ReadToEnd();
    }

    /// <summary>
    /// Check and return missing plugin settings
    /// </summary>
    /// <returns>Json Object containing any settings that failed the check</returns>
    private JObject PreRequisiteCheck()
    {
        var preReqs = new JObject();
        if (string.IsNullOrWhiteSpace(this.UserAPIKey))
        {
            preReqs.Add("userAPIKey", false);
        }

        return preReqs;
    }


    /// <summary>
    /// Route Request via Action
    /// </summary>
    private void RouteRequest(string actionName, HttpContext context)
    {
        HttpWebRequest httpWebRequest;
        var param = context.Request.HttpMethod;
        Log.Information("param is: " + param);



        if (param == "POST")
        {
            string json;
            using (var reader = new StreamReader(context.Request.InputStream))
            {
                json = reader.ReadToEnd();
            }
            RequestData data;
            try
            {
                data = JsonConvert.DeserializeObject<RequestData>(json);
            }
            catch (JsonException)
            {
                context.Response.StatusCode = 400; // Bad Request
                context.Response.Write("Invalid JSON");
                context.Response.End();
                return;
            }

            var action = data.action;
            var actionMessageText = data.actionMessageText;
            var encryptString = data.encryptString;
            var email = data.email;
            var WorkflowId = data.WorkflowId;
            var WorkflowStatusId = data.WorkflowStatusId;
            var actionMessageURL = data.actionMessageURL;
            var actionMessageId = data.actionMessageId;
            var mailNickname = data.mailNickname;
            var Firstname = data.Firstname;
            var Lastname = data.Lastname;
            var fullName = data.fullName;
            var requestId = data.requestId;


            Log.Information("Action is: " + action);
            Log.Information("Action name is: " + actionName);


            switch (action)
            {
                case "PreRequisiteCheck":
                    context.Response.Write(PreRequisiteCheck());
                    break;
                case "GetAllPages":
                    httpWebRequest = this.BuildRequest(this.BaseUrl + "pages");
                    context.Response.Write(this.ProcessRequest(httpWebRequest));
                    break;
                case "GetAllPageIncidents":
                    httpWebRequest = this.BuildRequest(this.BaseUrl + string.Format("pages/{0}/incidents", context.Request.QueryString["pageId"]));
                    context.Response.Write(this.ProcessRequest(httpWebRequest));
                    break;
                case "GetAllIncidentUpdates":
                    httpWebRequest = this.BuildRequest(this.BaseUrl + string.Format("pages/{0}/incidents/{1}", context.Request.QueryString["pageId"], context.Request.QueryString["incidentNumber"]));
                    context.Response.Write(this.ProcessRequest(httpWebRequest));
                    break;
                case "UpdatePushoverIncident":
                    httpWebRequest = this.BuildRequest(this.BaseUrl + string.Format("pages/{0}/incidents/{1}", context.Request.QueryString["pageId"], context.Request.QueryString["incidentNumber"]), this.GetPostRequestData(), "PUT");
                    context.Response.Write(this.ProcessRequest(httpWebRequest));
                    break;
                case "getWorkflowStatuses":


                    var workflowStatusService = new StatusBroker();
                    IdentifiedElement[] workflowsStatus = workflowStatusService.GetAllStatusesView();
                    string jsonWorkflowsStatus = JsonConvert.SerializeObject(workflowsStatus);
                    context.Response.Write(jsonWorkflowsStatus);
                    break;
                case "getWorkflows":


                    var workflowService = new AvailabilityManagementFacade();
                    IdentifiedElement[] workflows = workflowService.GetAllWorkflowsView();
                    string jsonWorkflows = JsonConvert.SerializeObject(workflows);
                    context.Response.Write(jsonWorkflows);
                    break;






                case "createActionMessage":
                    //Log.Information(context.Response);
                    Log.Information("case create action message: ");
                    this.actionMessageCreate.Persist(new MarvalSoftware.ServiceDesk.ActionMessage()
                    {
                        Name = "Pushover Integration Message - Automated",
                        IsHtml = false,
                        EntityType = NotificationRelatedEntityTypes.Request,
                        Identifier = 0,
                        // IsActive = true,
                        Content = actionMessageText
                    });
                    Log.Information("ActionMessage persisted successfully. Content: {Content}", actionMessageText);
                    context.Response.Write("{ \"response\": \"Installed Action Message Successfully" + "\" } ");
                    break;
                case "createActionRule":

                    var webhookMessage = new SendWebhookMessageBody
                    {
                        ActionMessageIdentifier = actionMessageId,
                        ActionMessageName = "Pushover Integration Message - Automated",
                        AuthenticationSessionId = null,
                        Body = "",
                        EntityIdentifier = 0,
                        RelatedEntityType = NotificationRelatedEntityTypes.Invalid,
                        Headers = new[]
                    {
    new SendWebhookMessageBody.Header(1, "Content-Type", "application/json")

   },
                        QueryString = "",
                        Url = actionMessageURL,
                        Verb = SendWebhookMessageBody.Verbs.Post,
                        AuthenticationType = MarvalSoftware.DataTransferObjects.IntegrationMessages.SendWebhookMessageBody.AuthenticationTypes.None,
                        UseBasicAuthentication = false,
                        Username = "",


                    };

                    // MarvalSoftware.DataTransferObjects.IntegrationMessages.SendWebhookMessageBody

                    ReferencedEntityInfo[] referencedEntities = { };
                    var groupPredicate = new GroupPredicate();
                    // groupPredicate.Predicates.Add(new MemberPredicate()
                    // {
                    //     Name = "IsNew",
                    //     Operator = MemberPredicate.Operators.Equals,
                    //     Value = true
                    // });
                    groupPredicate.Predicates.Add(new MemberPredicate()
                    {
                        Name = "Workflow",
                        Operator = MemberPredicate.Operators.Equals,
                        Value = WorkflowId
                    });
                    groupPredicate.Predicates.Add(new MemberPredicate()
                    {
                        Name = "Status",
                        Operator = MemberPredicate.Operators.Equals,
                        Value = WorkflowStatusId
                    });

                    //   groupPredicate.Predicates.Add(new MemberPredicate()
                    //  {
                    //      Name = "IsMajorIncident",
                    //      Operator = MemberPredicate.Operators.Equals,
                    //      Value = true
                    //  });

                    int ruleSetIds = 0;
                    using (var dataGrunt = new DataGrunt())
                    {
                        using (var dataReader = dataGrunt.ExecuteReader("ruleSet_getRuleSetIds", new DataGrunt.DataGruntParameter("ruleSetType", 5)))
                        {
                            var ruleSetIdOrdinal = dataReader.GetOrdinal("ruleSetId");
                            while (dataReader.Read())
                            {
                                ruleSetIds = dataReader.GetInt32(ruleSetIdOrdinal);

                            }
                        }
                    }



                    this.serviceDeskFacade.PersistRule(new MarvalSoftware.Rules.Rule()
                    {
                        Name = "Pushover Integration Rule - Automated",
                        Predicate = groupPredicate,
                        PredicateSummary = "",
                        Actions = new List<IRuleAction>() {
        new SendWebhookRuleAction
              {
                Predicate = null,
                Value = webhookMessage
              }
       },
                        ActionsSummary = "Web-hook to URL http://test.com with Body TestRequestActionMessage including Headers Authorization: TestingAuth,Content-Type: application/json using Verb Post",
                        IsActive = true
                    }, ruleSetIds, referencedEntities, "RequestClassificationFilter");

                    context.Response.Write("{ \"response\": \"Installed Action Rule Successfully" + "\" } ");
                    break;

                case "SendPushoverMessage":
                    //var postData = this.GetPostRequestData();

                    Log.Information("postdata should be: "+ json);

                    dynamic jsonBody = JsonConvert.DeserializeObject(json);
                    string userMessage = jsonBody.message;

                    var myPayload = new
                    {
                        token = APPToken,

                        user = UserAPIKey,

                        message = userMessage,
                        html = 1,
                    };
                    string payloadJson = JsonConvert.SerializeObject(myPayload);
                    // Information.log(payloadJson);

                    httpWebRequest = this.BuildRequest(this.BaseUrl, payloadJson, "POST");
                    context.Response.Write(this.ProcessRequest(httpWebRequest));

                    break;
                case "getGroups":
                        httpWebRequest = this.BuildRequest("https://api.pushover.net/1/groups.json?token=" + APPToken, null, "GET");
                        context.Response.Write(this.ProcessRequest(httpWebRequest));
                        break;
                    //default:

                    //    break;
            }
        }
        else
        {
           context.Response.Write("no info");
        }


    }

    /// <summary>
    /// Builds a HttpWebRequest
    /// </summary>
    /// <param name="uri">The uri for request</param>
    /// <param name="body">The body for the request</param>
    /// <param name="method">The verb for the request</param>
    /// <returns>The HttpWebRequest ready to be processed</returns>
    private HttpWebRequest BuildRequest(string uri = null, string body = null, string method = "GET")
    {
        //https://stackoverflow.com/a/2904963
        ServicePointManager.Expect100Continue = true;
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls12 | SecurityProtocolType.Ssl3;
        var request = WebRequest.Create(new UriBuilder(uri).Uri) as HttpWebRequest;
        request.Method = method.ToUpperInvariant();
        request.ContentType = "application/json";

        if (body != null)
        {
            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }
        }

        return request;
    }

    /// <summary>
    /// Proccess a HttpWebRequest
    /// </summary>
    /// <param name="request">The HttpWebRequest</param>
    /// <param name="credentials">The Credentails to use for the API</param>
    /// <returns>Process Response</returns>
    private string ProcessRequest(HttpWebRequest request)
    {
        fullResponse myRes = new fullResponse();
        try
        {
            request.Headers.Add("Authorization", "Bearer " + this.UserAPIKey);
            HttpWebResponse response = request.GetResponse() as HttpWebResponse;
            var res = "";
            using (StreamReader reader = new StreamReader(response.GetResponseStream()))
            {
                return reader.ReadToEnd();
            }

            //return myRes;

        }
        catch (WebException webEx)
        {
            var result = "";
            var errStatus = ((HttpWebResponse)webEx.Response).StatusCode;
            var errResp = webEx.Response;

            myRes.responseCode = Int32.Parse(errStatus.ToString());
            myRes.responseDes = ((HttpWebResponse)errResp).StatusDescription;
            var res = "";
            using (StreamReader reader = new StreamReader(errResp.GetResponseStream()))
            {
                res = reader.ReadToEnd();
            }
            //myRes.responseBody = res;
            HttpContext.Current.Response.StatusCode = (int)errStatus;
            HttpContext.Current.Response.ContentType = "application/json";
            HttpContext.Current.Response.Write(res);
            HttpContext.Current.Response.End();

            return null;


        }
    }
}
