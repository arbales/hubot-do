# hubot-do

## Chatting Dogether

Do Chat joins the power of Tasks, Projects, and Notifications with
simple real-time discussions, so your team can Do and plan practically
anything. *Do Chat is in Private Beta. If you're interested in testing
Chat before it's launched, send an e-mail to support@do.com.*

### Hubot + Do + Heroku = Like

1.  Create a [new Do account][do] for your robot to use. To simplify things,
    you might invite a user to your group from the sidebar. 
    **Tip:** You can use `youraddress+hubot@gmail.com` to create a new
    account without a seperate email address.

2.  You'll need to [apply for Do OAuth v2 credentials][oauth]. This
    typically takes less than a day, and will be automated in the next
    few weeks.

3.  [Download][hubot] the latest Hubot package. 

4.  Expand the `.zip` or `.tar.gz` file somewhere convenient, perhaps in
    `~/Workspace/`

5.  Edit `hubot/package.json` and add `hubot-do` to the dependencies
    section. It'll look something like...
   
    ```javascript
    "dependencies": {
      "hubot-do": "latest",
      "hubot": ">= 2.3.2",
      ...
    }
    ```

6.  Edit the `Procfile` and either add or replace the existing process to
    enable Hubot for Do. You can also use the `-n` option to name your
    robot. We call ours 'Cylon'.
        
        web: bin/hubot -a do -n Cylon
 
7.  Initialize a git repository in your hubot directory.
       
    ```sh
    cd hubot      
    git init
    git add .
    git commit -m "Initial Commit"
    ```

8.  Install the [Heroku Toolbelt][toolbelt] if you haven't already. 

9.  Create a Heroku application, and give it a cool name.

    ```sh
    heroku create mysterious-robot
    ```

10. We recommend adding the free [Redis To Go][redistogo] add-on so your robot
    can remember things. Memory is nice.

    ```sh
    heroku addons:add redistogo:nano
    ```

10. Setup the Do Hubot Adapter by adding your OAuth v2 credentials
    and your Hubot user's username and password.
    
    ```sh
    heroku config:add HUBOT_DO_CLIENT_ID=130f5290f86737a8a387ec335db5ea18f1db2160 \
      HUBOT_DO_CLIENT_SECRET=a4db718b998b87ff2e090c69c4918083a3834dfe \
      HUBOT_DO_USERNAME=austin+cylon@do.com \
      HUBOT_DO_PASSWORD=mariposa      
    ```

      **Security Advisory:** The user you created in step one will have
      access to your group just like any other. Additionally, anyone
      you add as a collaborator to your Hubot app on Heroku will be able
      to extract the password from the application's runtime. *Don't use
      the same password as your personal account.*

      If you're developing applications atop the Do platform, or wish to
      contribute to `hubot-do`, you can have `hubot-do` log activity on
      the client:

      ```sh
      heroku config:add HUBOT_DO_DEBUG=true
      ```

      Additionally, the `HUBOT_DO_DEBUG_VERBOSITY` variable allows you
      to specify the granularity of log messages you wish to receive. 
      Currently, events and errors are visible at level `2` and the full
      text of our push payloads are visible at level `3`.

11. With your fingers crossed, and heart set, deploy and start your
    Hubot instance!

    ```sh
    git push heroku master
    heroku ps:scale web=1
    ```

12. Login to [Do][1] with your Hubot's e-mail address and password. Then
    join any chat rooms you'd like it to participate in. **Future
    releases of hubot-do will automagically join all available rooms.**

### Running Locally      

To run your Hubot for Do locally, you should `touch .env` in your hubot
directory and define your enviroment variables there. [Learn more][foreman] about
Foreman and .env files.

### Chat Beta Service

The use of the Do API is subject to the terms and conditions found at
[do.com/legal][legal]. Take care to note Section 8.4:

> Any Non-GA Services will be clearly designated as beta, pilot, limited release, developer preview, non-production or by a description of similar import. Non-GA Services are provided for evaluation purposes and not for production use, are not supported, may contain bugs or errors, and may be subject to additional terms. NON-GA SERVICES ARE NOT CONSIDERED "SERVICES" HEREUNDER AND ARE PROVIDED "AS IS" WITH NO EXPRESS OR IMPLIED WARRANTY. We may discontinue Non-GA Services at any time in Our sole discretion and may never make them generally available.
      
### Contributions

Patches and bug reports are welcome. Just send a [pull request][pullrequests] or
file an [issue][issues]. [Project changelog][changelog].

[License][license]

[do]:           https://do.com "Do by Salesforce"
[oauth]:        https://doworktogether.wufoo.com/forms/do-api-application/ "Do OAuth Application"
[hubot]:        https://github.com/github/hubot/downloads "Hubot Downloads"
[toolbelt]:     https://toolbelt.heroku.com "Heroku Toolbelt"
[redistogo]:    http://devcenter.heroku.com/articles/redistogo "Redis To Go Addon"
[foreman]:      http://ddollar.github.com/foreman/#ENVIRONMENT "Foreman ENVIRONMENT"
[legal]:        https://do.com/legal "Do Legal Aggreement" 
[pullrequests]: https://github.com/arbales/hubot-do/pulls
[issues]:       https://github.com/arbales/hubot-do/issues
[changelog]:    https://github.com/arbales/hubot-do/blob/master/CHANGELOG.md
[license]:      https://github.com/arbales/hubot-do/blob/master/LICENSE

