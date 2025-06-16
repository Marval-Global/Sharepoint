# Pushover Plugin for MSM

## MSM-Pushover Integration

This plugin allows you to send push notifications through the Pushover application. You are also able to create action rules and action messages through the Pushover plugin page.

## Pushover Integration

**Settings needed from Pushover:**

Within Pushover follow the steps outlined below:

1. Navigate to https://pushover.net/
2. Signup / Login (You will see your user token here after signing in)
3. Scroll down to applications and create an application (You will see your APP(API) Token here)
4. (Optional) If desired create a group and add all desired users to that group (You will see the group key here)


## Compatible Versions

| Plugin  | MSM       |Pushover|
|---------|-----------|----------|
| 1.0.0   | 14.15.0   | v1.0.0   |
| 1.0.4   | 15.11+    | v4.0.0   |


## Installation

Please see your MSM documentation for information on how to install plugins.

Once the plugin has been installed you will need to configure the following settings within the plugin page:

+ *User Api Key*: The user API key of who you want to send the notification to (Can be found through step 2). You can also use the group key here instead if you wish to send a notification to a group. (Can be found through step 4)
+ *App Token*: Your application's API Token. (Can be found through step 3)


## Usage

The plugin can be launched from the quick menu after you load a new or existing request.
You can also create action rules and messages through the maintenance -> system -> plug-ins page.

## Contributing

We welcome all feedback including feature requests and bug reports. Please raise these as issues on GitHub. If you would like to contribute to the project please fork the repository and issue a pull request.
