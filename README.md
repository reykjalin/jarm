# Jarm

[![builds.sr.ht status](https://builds.sr.ht/~reykjalin/jarm/commits/main/build_ubuntu_release.yml.svg)](https://builds.sr.ht/~reykjalin/jarm/commits/main/build_ubuntu_release.yml?)

Jarm provides an easy and simple way to share updates with family and friends in the form of photos, videos, and text updates.

Screenshots and a better introduction are available at [thorlaksson.com/projects/jarm/](https://www.thorlaksson.com/projects/jarm).

## Goals

- Private; intended for family and friends. Invite only.
- Easy setup and management.

## Non-Goals

- Direct messages
- Federation
- Publically accessible

---

## Server setup

### Dependencies

Jarm depends on several external executables being available in your environment:

- `ffmpeg` via [FFMPEG](https://ffmpeg.org/).
- `ffprobe` via [FFMPEG](https://ffmpeg.org/).
- `magick` via [ImageMagick](https://imagemagick.org/).
- `convert` via [ImageMagick](https://imagemagick.org/).
- `identify` via [ImageMagick](https://imagemagick.org/).
- `sqip` via [SQIP](https://github.com/axe312ger/sqip).
  - Jarm currently depends on the v1 alpha installed via `npm install --global sqip-cli@canary`.
  - SQIP is an npm packages and depends on Node >= v8.

### Build a release

```sh
mix deps.get --only prod
MIX_ENV=prod mix compile
npm install --prefix ./assets
npm run deploy --prefix ./assets
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
```

### Create an env file

This will be used by systemd to set up the environment.

To illustrate what this might look like let's assume you store your runtime files, like the database, in `/opt/jarm/`:

```sh
DATABASE_PATH="/opt/jarm/jarm.db"
URL="example.com"
ADMIN_EMAIL="admin@example.com"
SMTP_USERNAME="admin@example.com"
SMTP_PASSWORD="<email_password>"
SMTP_SERVER="smtp.example.com"
SMTP_PORT=465
SECRET_KEY_BASE="<secret_key>"
LIVE_VIEW_SIGNING_SALT="<secret_signing_salt>"
```

### Migrate the database

```sh
# First, source your environment variables
source /opt/jarm/jarm_env
export $(cut -d= -f1 /opt/jarm/jarm_env )
jarm eval 'Jarm.Release.migrate()'
```

### Start Jarm

Using the provided systemctl script from `scripts/jarm.service`:

```sh
systemctl start jarm
```

Running the release directly:

```sh
jarm start
```

This will run a bare HTTP server on port 4000. It's recommended that you run a reverse proxy via a webserver like Apache, Nginx, or Caddy in front of the application.

### Send an invitation

```sh
jarm rpc 'Jarm.Release.send_invitation("<email>")'
```

or, if you already have an account set up, navigate to /users/invite on your site.

### Grant administrator privileges to an account

```sh
jarm rpc 'Jarm.Release.grant_administrator_privileges_to("<email_for_existing_account>")'
```

Currently the CLI method is the only supported way to promote someone to an administrator.

---

## Roadmap

**V0.1**

- SQLite
- Accounts
  - [x] Send invitation via CLI
  - [x] Reset password
  - [x] Username, password, date created

**V0.2**

- Deployment
  - [x] Move build-time configurations into runtime configurations
  - [x] Build manifest for generating releases and build artifacts on [Sourcehut](https://builds.sr.ht/~reykjalin/jarm)
  - [x] Automatic HTTPS via [SiteEncrypt](https://github.com/sasa1977/site_encrypt)
  - [x] Example `systemd` scripts

**V0.3**

- [x] Posts
  - Username
  - Date
  - Message
  - Parent post (for comments — later)

**V0.4**

- Timeline
  - [x] Display posts (username, date, message)
  - [x] [Pagination](https://stackoverflow.com/questions/14468586/efficient-paging-in-sqlite-with-millions-of-records/14468878)
- [x] Edit post
- [x] Delete post
- [x] Only allow owner to edit and delete posts.
- [x] User roles via [canada](https://github.com/jarednorman/canada); admin — moderator — user, or equivalent.

**V0.5**

- Photos in posts
  - [x] Add photos to posts
- Videos in posts
  - [x] Add videos to posts

**V0.6**

- [x] Better styles via Tailwind CSS.
- [x] Basic caching.
- [x] Thumbnails for videos.
- [x] Compression for photos (imagemagick converts to webp).
- [x] Compression for videos (ffmpeg converts to mp4 w/ max bitrate of 2Mbps).
- [x] Links to original videos and images provided.
- [x] Phoenix updated to v1.6.
- [x] Post page moved out of a live modal to its own page.

**V0.7**

- Photos
  - [ ] Edit photos in posts
  - [ ] Delete photos in posts
- Videos
  - [ ] Edit videos in posts
  - [ ] Delete videos in posts

**V1 - micro-birdsite**

- [x] Single binary ready
- User profiles
  - [ ] Post overview
  - [ ] Media overview
  - [ ] Profile photos
- [ ] Documentation for server management, build, develop, etc.
- Blog posts

**V2 - Admin UI and CLI**

- Admin commands
  - [ ] Delete account by username, id, email
  - [ ] Send password reset
  - [ ] Set timezone — handled by the server instead of the software?
  - Delete specific photo by post
  - Delete specific video by post
  - Delete specific media by post

**V3 - activity digest**

- [x] Comments on posts
- [x] Daily/weekly digest email
  - Comments on your posts
  - Comments on posts you commented on
  - Summary of new posts
- Post version history
  - [ ] Store versions in database
  - [ ] Show “X revisions” label
  - [ ] Display revisions

**V4 - optimizations**

- [ ] Accept markdown via [earmark](https://github.com/pragdave/earmark) and [html_sanitize_ex](https://github.com/rrrene/html_sanitize_ex) and save as HTML in DB.
- [ ] Export photo data
- [x] Lazy loading for images
- [x] Lazy loading for videos
- Delete unused photos
- Delete unused videos

**V5 - data export**

- Create zip of all photos
- Create zip of photos from user
- Create zip of all videos
- Create zip of all media
- Create create zip of all videos by user
- Create zip of all media by user
- [ ] Export all data on user in CSV

**V6 Third-party integrations**

- [Telegram integration](https://github.com/rockneurotiko/ex_gram)?
- Instagram integration?
- Facebook integration?
- Matrix integration?

**V7 - Accessibility**

- Accessibility audit and fixes
  - [ ] `alt` text in `<img>` elements

**V8 - For the admins**

- Admin UI
  - [x] Send invitation
  - Delete accounts
  - Delete comments
  - Delete posts
  - Change URL
  - Setup email credentials for server

**V9 - translations**

- [x] Support translations for in-app strings
- Support custom translations for posts/comments
- [x] Add Icelandic translations
- [x] Add Filipino translations

**V10 - timelines**

- Timeline for “follow only” / Timeline for "non-muted"
- Timeline for everyone on instance
- Change new post notifications to have 2 sections; one per timeline

**V11 - visibility**

- Website for the project

**V12 - read-only API**

- GraphQL api for read only access

**Future possibilities**

- Mobile apps
  - iOS
  - Android
  - PWA?
- Desktop apps
  - Qt6/Tk
- Gemini support

**V13 - mobile apps?**

- iOS
- Android
- PWA?
