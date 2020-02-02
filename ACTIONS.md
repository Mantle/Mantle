We use GitHub Actions in order to help automate deployment, check build quality, & other tasks. You can add, edit, & view our GitHub actions by running the following commands in Terminal when in the repo's base directory:

```
open .github/workflows
```

## cocoapods-publish

Deployment of new versions to CocoaPods requires that we submit a [new podspec](https://github.com/Mantle/Mantle/blob/master/Mantle.podspec) with the correct tag & version set from a trusted owner's account. Whenever a new tag is pushed, we submit the podspec with the version pulled from the tag automatically.

Requires CocoaPods Trunk token. Owners listed in the podspec are all able to generate a new token & add it into the Secret's tab of this repo's Settings page.

### Updating CocoaPods Trunk Token

The CocoaPods Trunk token expires over time and must be updated every 5 months or so.

All the owners listed in our [podspec](https://github.com/Mantle/Mantle/blob/master/Mantle.podspec) have the repository permissions & the CocoaPods ownership claims to update the token. They must also be able to receive email to mantle-cocoapods@robb.is that [robb](https://github.com/robb) set up.

If you are one of these owners, perform the following:

1. Register a Cocoapods Trunk session like so `pod trunk register mantle-cocoapods@robb.is 'Mantle GitHub Actions' --description='Mantle GitHub Actions'`
2. An email will be sent to mantle-cocoapods@robb.is. Click the link in the email to activate the session.
3. Retrieve the created token via `pod trunk me --verbose`

  You'll see output like this:

  ```
opening connection to trunk.cocoapods.org:443...
opened
starting SSL for trunk.cocoapods.org:443...
SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
<- "GET /api/v1/sessions HTTP/1.1\r\nContent-Type: application/json; charset=utf-8\r\nAccept: application/json; charset=utf-8\r\nUser-Agent: CocoaPods/1.7.4\r\nAuthorization: Token XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nHost: trunk.cocoapods.org\r\n\r\n"
-> "HTTP/1.1 200 OK\r\n"
-> "Date: Sun, 22 Sep 2019 05:11:46 GMT\r\n"
-> "Connection: keep-alive\r\n"
-> "Strict-Transport-Security: max-age=31536000\r\n"
-> "Content-Type: application/json\r\n"
-> "Content-Length: 1491\r\n"
-> "X-Content-Type-Options: nosniff\r\n"
-> "Server: thin 1.6.2 codename Doc Brown\r\n"
-> "Via: 1.1 vegur\r\n"
-> "\r\n"
  ```

  `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` in the Authorization Token is the Cocoapods Trunk Token. This should never be published publicly.

4.  Go to the [Mantle GitHub page -> Settings -> Secrets](https://github.com/Mantle/Mantle/settings/secrets) & add the token as the secret named `COCOAPODS_TRUNK_TOKEN`

## stale

The `Mark stale issues and pull requests` workflow is our GitHub bot action to mark issues & PRs with no activity for 30 days as stale & if no response is made within 5 days, close the issue automatically.

## xcodebuild

This workflow simply builds on commit pushes to ensure nothing breaks the build.