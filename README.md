# Inner Circle

[![builds.sr.ht status](https://builds.sr.ht/~reykjalin/inner_circle.svg)](https://builds.sr.ht/~reykjalin/inner_circle?)

Inner Circle provides an easy and simple way to share updates with family and friends in the form of photos, videos, and text updates.

## Goals

- Private; intended for family and friends. Invite only.
- Easy setup and management.

## Non-Goals

- Direct messages
- Federation
- Publically accessible

---

## Server setup

### Build a release

```sh
mix deps.get --only prod
MIX_ENV=prod mix compile
npm install --prefix ./assets
npm run deploy --prefix ./assets
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
```

### Migrate the database

```sh
inner_circle eval 'InnerCircle.Release.migrate()'
```

### Start Inner Circle

```sh
inner_circle start
```

### Send an invitation

```sh
inner_circle rpc 'InnerCircle.Release.send_invitation("<email>")'
```

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
  - [x] Build manifest for generating releases and build artifacts on [Sourcehut](https://builds.sr.ht/~reykjalin/inner_circle)
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

**V0.6**

- Photo compression? Probably via [mogrify](https://github.com/elixir-mogrify/mogrify)
- Thumbnail generation via [thumbnex](https://github.com/talklittle/thumbnex)

**V0.7**

- Comments on posts
- [ ] Accept markdown via [earmark](https://github.com/pragdave/earmark) and [html_sanitize_ex](https://github.com/rrrene/html_sanitize_ex) and save as HTML in DB.

**V0.8**

- Lazy loading for images

**V0.9**

- Profile photos

**V0.10**

- Export photo data

**V0.11**

- Documentation for server management, build, develop, etc.

**V1 - micro-birdsite**

- [x] Single binary ready
- Admin commands
  - [ ] Delete account by username, id, email
  - [ ] Send password reset
  - [ ] Set timezone — handled by the server instead of the software?
  - [ ] Export all data on user in CSV
- Blog posts

**V2 - photos**

- Lazy loading for images
- Admin commands
  - Generate thumbnails
  - Compress photos
  - Delete unused photos
  - Create zip of all photos
  - Create zip of photos from user
  - Delete specific photo by post

**V3 - videos**

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

**V4 - activity digest**

- Daily/weekly digest email
  - Comments on your posts
  - Comments on posts you commented on
  - Summary of new posts
- Post version history
  - [ ] Store versions in database
  - [ ] Show “X revisions” label
  - [ ] Display revisions

**V5 Third-party integrations**

- [Telegram integration](https://github.com/rockneurotiko/ex_gram)?
- Instagram integration?
- Facebook integration?
- Matrix integration?

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
