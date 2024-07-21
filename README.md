# ✨ Sparkles ✨

Sparkles is a simple little Slack application for recognizing people in the form of ~~meaningless internet points~~ sparkles!

## Usage

Tip: You can always view usage information in Slack using `/sparkle help`

### Give a sparkle to somebody

To sparkle someone, use `/sparkle` immediately followed by a username and, optionally, a reason:

`/sparkle @davidcelis [reason]`

Reasons don’t require any particular format, but if you want them to flow better when reading them later, it’s best to start any reason with a coordinating conjunction (that’s just a fancy way to say words like "for",  "because", or "so").

`/sparkle @davidcelis for being so awesome`

## Self-hosting

Both the slack application and [sparkles.lol](https://sparkles.lol) are free to use! Except for the reasons given for sparkles, we never store messages from Slack itself, and the OAuth scopes requested are minimal:

* `commands` (adds the `/sparkle` command to your workspace)
* `chat:write` (so we can post a confirmation when someone gives out a sparkle)
* `reactions:read` (so we can give people a sparkle via emoji reactions)
* `users:read` (so we can confirm that the user you’re trying to give a sparkle to is a member of the workspace)

However, maybe you work for an organization with extremely strict rules about what data is allowed into or out of Slack. If that’s the case, Sparkles is easy to host yourself! In fact, with only a little bit of configuration, you can host Sparkles on Heroku or with Dokku.

### Requirements

Sparkles is a Rails application using the following dependencies:

* Ruby 3 (and Bundler)
* PostgreSQL 16

At least, these are the versions in use upon writing this README. Depending on the dependency, they may be updated randomly; the publicly available Sparkles application is hosted via Dokku, so dependency management is less of a concern. For this reason, I highly recommend hosting via a service like Heroku or Dokku so that you can take advantage of buildpacks.

### Create a Slack application

Slack recently made it easy to create a preconfigured Slack application using App Manifests. Visit https://api.slack.com/apps?new_app=1 and choose the option to create an app from an app manifest. Choose a development workspace (it’s best to choose one that you control so that you can install Sparkles yourself without requiring review from a workspace admin) and paste in the contents of our example [app_manifest.yml](config/app_manifest.example.json) file, making sure to replace `example.com` in any URL with the domain where you’re planning to host Sparkles.

### Generate an encrypted credentials file

Newer Rails applications use encrypted YAML files to store application secrets. You’ll need to generate one with your own credentials:

```sh
$ bin/rails credentials:edit
```

This will create two new files: `config/credentials.yml.enc` and `master.key`. Keep the former in version control and keep the latter excluded. Our standard `.gitignore` file handles this for you.

When you run the above command, you should find yourself in a text editor for the `config/credentials.yml.enc` file; paste the following in, adding adding the required values:

```yaml
# Found on your Slack application's "Basic Information" page
slack:
  client_id: # required
  client_secret: # required
  signing_secret: # required

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

You can deploy Sparkles however you like; the only required process is the Rails server itself (Puma, by default) to handle web requests. Sparkles includes a `Procfile` to declare these processes, so deployment to a service like Heroku or Dokku is easy. However you deploy, you’ll need to define a couple environment variables:

* `DATABASE_URL`: A connection string for a PostgreSQL database. This is defined automatically for you if you’re using something like Heroku or Dokku and add the PostgreSQL plugin/resource.
* `RAILS_MASTER_KEY`: The contents of the `master.key` file you generated earlier.

## Development

Encountered a bug? Have an idea for something that Sparkles doesn’t do yet? Feel free to [file an issue](https://github.com/davidcelis/sparkles/issues/new). Or, if you’re a developer yourself, [fork the repository](https://github.com/davidcelis/sparkles/fork), make some changes, and open a Pull Request!


## Acknowledgements

Sparles is inspired by an [old Hubot script](https://github.com/pmn/sparkles/blob/master/scripts/sparkles.coffee) that was very popular at GitHub and gave us a fun, silly way to show appreciation to fellow hubbers. Everybody loved sparkles except [@scottjg](https://github.com/scottjg) and [@dreww](https://github.com/dreww).
