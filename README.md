# Inner Circle

Inner Circle provides an easy and simple way to share updates with family and friends in the form of photos, videos, and text updates.

## Goals

- Private; intended for family and friends. Invite only.
- Easy setup and management.

## Non-Goals

- Direct messages
- Federation
- Publically accessible

## Server setup

### Build a release

```sh
MIX_ENV=prod mix release
```

### Start the release so you can migrate the database and send an invitation for the first account

```sh
inner_circle start_iex
iex> InnerCircle.Release.migrate
# ...
iex> InnerCircle.Release.send_invitation("<email>")
```

Then press <ctrl-C> to exit the prompt.

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
  - [ ] Docker file for building specific releases
  - [ ] Automatic HTTPS via [SiteEncrypt](https://github.com/sasa1977/site_encrypt)
  - [ ] Example `systemd` scripts

**V0.3**

- [ ] Posts
  - Username
  - Date
  - Message
  - Parent post (for comments — later)

**V0.4**

- Timeline
  - [ ] Display posts (username, date, message)
  - [ ] Pagination

**V0.5**

- [ ] Edit post
- Post version history
  - [ ] Store versions in database
  - [ ] Show “X revisions” label
  - [ ] Display revisions

**V0.6**

- [ ] Move runtime e-mail configuration into in-module configuration
- [ ] User roles; admin — moderator — user

**V0.7**

- Documentation for server management, build, develop, etc.

**V1 - micro-birdsite**

- [ ] Single binary ready
- [ ] Automatic SSL cert management
- Admin commands
  - [ ] Delete account by username, id, email
  - [ ] Send password reset
  - [ ] Set timezone
  - [ ] Set email credentials
  - [ ] Set URL
  - [ ] Export all data on user in CSV
- Blog posts

**V1.1**

- Photos in posts

**V1.2**

- Photo compression
- Thumbnail generation

**V1.3**

- Comments on posts

**V1.4**

- Lazy loading for images

**V1.5**

- Profile photos

**V1.6**

- Export photo data

**V2 - photos**

- Lazy loading for images
- Admin commands
  - Generate thumbnails
  - Compress photos
  - Delete unused photos
  - Create zip of all photos
  - Create zip of photos from user
  - Delete specific photo by post

**V4 - videos**

- videos in updates
- Video compression?
- Thumbnail generation for videos
- Lazy loading for videos
- Add new info to data export
- Admin commands
  - Generate thumbnails
  - Compress videos
  - Delete unused videos
  - Create zip of all videos
  - Create zip of all media
  - Create create zip of all videos by user
  - Create zip of all media by user
  - Delete specific video by post
  - Delete specific media by post

**V5 - activity digest**

- Daily/weekly digest email
  - Comments on your posts
  - Comments on posts you commented on
  - Summary of new posts

**V6 - CSS and accessibility**

- Better styles
- Accessibility audit and fixes

**V7 - For the admins**

- Admin UI
  - Send invitation
  - Delete accounts
  - Delete comments
  - Delete posts
  - Change URL
  - Setup email credentials for server

**V8 - translations**

- Support translations for in-app strings
- Support custom translations for posts/comments
- Add Icelandic translations

**V9 - timelines**

- Timeline for “follow only”
- Timeline for everyone on instance
- Change new post notifications to have 2 sections; one per timeline

**V10 - visibility**

- Website for the project

**V11 - read-only API**

- GraphQL api for read only access

**Future possibilities**

- Mobile apps
  - iOS
  - Android
  - PWA?
- Desktop apps
  - Qt6/Tk
- Gemini support

**V12 - mobile apps?**

- iOS
- Android
- PWA?
