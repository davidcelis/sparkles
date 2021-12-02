# ✨ Sparkles ✨

Sparkles is a simple little Slack application for recognizing your teammates and friends in the form of ~~meaningless internet points~~ sparkles. When installed to a Slack workspace, a `/sparkle` slash command is added and you can get started immediately!

<p align="center">
  <a href="https://slack.com/oauth/v2/authorize?client_id=2647606822032.2647619142080&scope=channels:join,channels:read,commands,groups:read,reactions:read,team:read,users:read,chat:write&user_scope=openid">
    <img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack.png" srcSet="https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x"/>
  </a>
</p>

## Usage

Tip: You can always view usage information in Slack using `/sparkle help`

### Give a sparkle to somebody

To sparkle someone, use `/sparkle` immediately followed by a username and, optionally, a reason:

`/sparkle @davidcelis [reason]`

Reasons don't require any particular format, but if you want them to flow better when reading them later, it's best to start any reason with a coordinating conjunction (that's just a fancy way to say words like "for",  "because", or "so").

`/sparkle @davidcelis for being so awesome`

### View your team's leaderboard

Once Sparkles has been installed to your slack workspace, any member of your team can go to [sparkles.lol](https://sparkles.lol) to sign into the web frontend and view the team leaderboard!

You can also view the leaderboard in Slack using the `/sparkle` command. Some Slack teams get pretty big, though, so leaderboards viewed this way are kept to the top ten sparklers.

`/sparkle stats`

### View your sparkles

When looking at the team leaderboard on [sparkles.lol](https://sparkles.lol), you can click anybody's username to see a complete history of their sparkles. This includes all kinds of handy information! You can see who gave each sparkle, what their reasons were, the Slack channel where it happened, and even a handy permalink back to the original message in Slack where Sparklebot worked its magic.

Like with the full leaderboard, you can also see anybody's ten most recent sparkles right within slack:

`/sparkle stats @davidcelis`

### Adjust your experience with Sparkles

There are a couple options you can configure when using Sparkles to personalize your experience:

`/sparkle settings`

Running this command will open a modal with the settings you can adjust. As a regular teammate, you can opt out of leaderboard functionality, hiding point totals when using `/sparkle` or the web front-end. If you think the leaderboard takes away from the fun of Sparkles and would rather have a more zen experience, turn it off!

If you're an admin for your Slack team, you have a couple additional options:

* You can disable the leaderboard team-wide. You can still view stats on an individual basis and see the usual detail per-sparkle, but the leaderboard will become a simple team directory and point totals won't be shown anywhere.
* You can select a public channel to act as your Sparkle feed! Any sparkles given in public channels will be shared to this channel so that nobody needs to feel out of the Sparkle loop.

## Self-hosting

Both the slack application and [sparkles.lol](https://sparkles.lol) are free to use! Except for the reasons given for sparkles, we never store messages from Slack itself. However, maybe you work for an organization with strict rules about what data is allowed into or out of Slack. If that's the case, Sparkles is easy to host yourself! In fact, with only a little bit of configuration, you can host Sparkles on Heroku or with Dokku.

### Requirements

Sparkles is a Rails application using the following dependencies:

* Ruby 3.0.3 (and Bundler)
* Node v12.16.2 (and Yarn)
* PostgreSQL 13.4
* Redis 6.2.6

At least, these are the versions in use upon writing this README. Depending on the dependency, they may be updated randomly; the publicly available Sparkles application is hosted via Dokku, so dependency management is less of a concern. For this reason, I highly recommend hosting via a service like Heroku or Dokku so that you can take advantage of buildpacks.

### Create a Slack application

Slack recently made it easy to create a preconfigured Slack application using App Manifests. Visit https://api.slack.com/apps?new_app=1 and choose the option to create an app from an app manifest. Choose a development workspace (it's best to choose one that you control so that you can install Sparkles yourself without requiring review from a workspace admin) and paste in the contents of our example [app_manifest.yml](config/app_manifest.example.yml) file, making sure to replace `example.com` in any URL with the domain where you're planning to host Sparkles.

### Generate an encrypted credentials file

Newer Rails applications use encrypted YAML files to store application secrets. You'll need to generate one with your own credentials:

```sh
$ bin/rails credentials:edit
```

This will create two new files: `config/credentials.yml.enc` and `master.key`. Keep the former in version control and keep the latter excluded. Our standard `.gitignore` file handles this for you.

When you run the above command, you should find yourself in a text editor for the `config/credentials.yml.enc` file; paste the following in, adding adding the required values:

```yaml
# Found on your Slack application's "Basic Information" page
slack:
  client_id: # or set a SLACK_CLIENT_ID environment variable
  client_secret: # or set a SLACK_CLIENT_SECRET environment variable
  signing_secret: # or set a SLACK_SIGNING_SECRET environment variable

# An ingestion URL for error handling using Sentry. This isn't required, but
# Sentry has a generous free tier, so you may as well sign up and set up a
# quick project at http://sentry.io/signup/
#
# Example: https://aa80f6df85a993c7657ec39a0@o12345.ingest.sentry.io/1234567
sentry_dsn: # optional, a SENTRY_DSN environment variable works as well

# Used as the base secret for all MessageVerifiers in Rails, including the one
# protecting cookies. Generate one by running `rails secret`.
secret_key_base: # required
```

### Deploy the Rails application

You can deploy Sparkles however you like; the only two required processes are the Rails server (Puma, by defualt) to handle web requests, and Sidekiq to handle background job processing. Sparkles includes a `Procfile` to declare these processes, so deployment to a service like Heroku or Dokku is easy. However you deploy, you'll need to define three environment variables:

* `DATABASE_URL`: A connection string for a PostgreSQL database. This is defined automatically for you if you're using something like Heroku or Dokku and add the PostgreSQL plugin/resource.
* `REDIS_URL`: A connection string for a Redis database. This is defined automatically for you if you're using something like Heroku or Dokku and add the Redis plugin/resource.
* `RAILS_MASTER_KEY`: The contents of the `master.key` file you generated earlier.
* `SLACK_CLIENT_ID` (optional): The Client ID of your Slack application if you'd rather provide it in the environment instead of the `credentials.yml.enc` file
* `SLACK_CLIENT_SECRET` (optional): The Client Secret of your Slack application if you'd rather provide it in the environment instead of the `credentials.yml.enc` file
* `SLACK_SIGNING_SECRET` (optional): The Signing Secret of your Slack application if you'd rather provide it in the environment instead of the `credentials.yml.enc` file

## Development [![View performance data on Skylight](https://badges.skylight.io/status/wrjfnvXfyKpB.svg)](https://oss.skylight.io/app/applications/wrjfnvXfyKpB)

Encountered a bug? Have an idea for something that Sparkles doesn't do yet? Want to help [make the app faster](https://oss.skylight.io/app/applications/wrjfnvXfyKpB)? Feel free to [file an issue](https://github.com/davidcelis/sparkles/issues/new). Or, if you're a developer yourself, [fork the repository](https://github.com/davidcelis/sparkles/fork), make some changes, and open a Pull Request!


## Acknowledgements

Sparles is inspired by an [old Hubot script](https://github.com/pmn/sparkles/blob/master/scripts/sparkles.coffee) that was very popular at GitHub and gave us a fun, silly way to show appreciation to fellow hubbers. Everybody loved sparkles except [@scottjg](https://github.com/scottjg) and [@dreww](https://github.com/dreww).
