# Connexions [![Build Status](https://travis-ci.org/Connexions/webview.svg?branch=master)](https://travis-ci.org/Connexions/webview) [![dependency Status](https://david-dm.org/Connexions/webview.svg)](https://david-dm.org/Connexions/webview#info=dependencies) [![devDependency Status](https://david-dm.org/Connexions/webview/dev-status.svg)](https://david-dm.org/Connexions/webview#info=devDependencies)

Below are instructions for hosting and building the site and a layout of how the code is organized.

CNX webview is designed to be run as a frontend for [cnx-archive](https://github.com/Connexions/cnx-archive).

# Installing

1. If necessary, install [Node.js](http://nodejs.org) and npm (which is included with Node.js).
2. From the root `webview` directory, run `./script/bootstrap` in the command line.
3. Now run `./script/setup` to install all the package dependencies.
  * **Note:** `npm install` runs `bower install` and `grunt install`, both of which can also be run independently
    * `bower install` downloads front-end dependencies
    * `grunt install` compiles the Aloha-Editor (which is downloaded by bower)

By default, webview will use [cnx-archive](https://github.com/Connexions/cnx-archive) and [cnx-authoring](https://github.com/Connexions/cnx-authoring) hosted on cnx.org.


# Building

From the root `webview` directory, run `./script/setup`.

The `dist` directory containing the built site will be added to the root `webview` directory.

# Testing

From the root `webview` directory, run `./script/test` (which runs `npm test`).
npm test failures are not as informative as they could be.
If `coffeelint` fails, you can run it with `grunt coffeelint` to get more information

# Updating

From the root `webview` directory, run `./script/update`, which executes the following commands:
1. `npm update`
2. `bower update`
3. `grunt aloha --verbose`

# Hosting

### Quick Development Setup

1. Install [nginx](http://nginx.org/)
2. Run `./script/start` (uses `nginx.dev.conf`)
3. (optional) Install https://github.com/prerender/prerender
4. Point your browser to [http://localhost:8000](http://localhost:8000)
5. Run `./script/stop` to stop nginx

### Customization Notes

1. Update settings in `src/scripts/settings.js` if necessary to, for example, include
the correct Google Analytics ID, and to point to wherever `cnxarchive` is being hosted.

For example, if the data you are working with is located on `devb.cnx.org`, you can change `src/scripts/settings.js` as follows:

```
cnxarchive: {
  host: 'archive-devb.cnx.org',
  port: 80
},
```

2. Ensure resources are being served with the correct MIME type, including fonts.
  * Example nginx MIME types that may need to be added:

  ```nginx
    types {
        image/svg+xml           svg svgz;
        font/truetype           ttf;
        font/opentype           otf;
        application/font-woff   woff;
    }
  ```

3. Configure your server to point at `dist/index.html` (or `src/index.html` for development)
  * Unresolveable URIs should load `dist/index.html` or `src/index.html`
  * If not hosting the site from the domain root, update `root` in `src/scripts/settings.js`
  * `scripts`, `styles`, and `images` routes should be rewritten to the correct paths

#### Example nginx config

You can, for example, point at the server hosting the `cnxarchive` you want to work with. This will point all the resources to the proper server.

```
server {
    listen 8000; # dev
    listen [::]:8000; # dev ipv6
    listen 8001; # production
    listen [::]:8001; # production ipv6
    server_name  _;

    # Support both production and dev
    set $ROOT "src";
    if ($server_port ~ "8001") {
        set $ROOT "dist";
    }

    root /path/to/webview/$ROOT/;

    index index.html;
    try_files $uri @prerender;

    # Proxy resources and exports to cnx.org
    # since they are not part of the locally hosted package
    location /resources/ {
        proxy_pass http://cnx.org;
    }
    location /exports/ {
        proxy_pass http://cnx.org;
    }

    # For development only
    location ~ ^.*/bower_components/(.*)$ {
        alias /path/to/webview/bower_components/$1;
    }

    location ~ ^.*/(data|scripts|styles|images|fonts)/(.*) {
        try_files $uri /$1/$2;
    }

    # Prerender for SEO
    location @prerender {
        # Support page prerendering for web crawlers
        set $prerender 0;
        if ($http_user_agent ~* "baiduspider|twitterbot|facebookexternalhit|rogerbot|linkedinbot|embedly|quora link preview|showyoubot|outbrain|pinterest") {
            set $prerender 1;
        }
        if ($args ~ "_escaped_fragment_") {
            set $prerender 1;
        }
        if ($http_user_agent ~ "Prerender") {
            set $prerender 0;
        }
        if ($uri ~ "\.(js|css|xml|less|png|jpg|jpeg|gif|pdf|doc|txt|ico|rss|zip|mp3|rar|exe|wmv|doc|avi|ppt|mpg|mpeg|tif|wav|mov|psd|ai|xls|mp4|m4a|swf|dat|dmg|iso|flv|m4v|torrent)") {
            set $prerender 0;
        }
        if ($prerender = 1) {
            rewrite .* /$scheme://$http_host$request_uri? break;
            proxy_pass http://localhost:3000;
        }
        if ($prerender = 0) {
            rewrite .* /index.html break;
        }
    }
}
```
**Note:** make sure to disable your browser's cache to view changes made to `./conf/nginx.dev.conf`. For example, in Chrome's console, under the network tab, check "Disable Cache".




# Directory Layout

* `bower_components/`           3rd Party Libraries *(added after install)*
* `node_modules/`               Node Modules *(added after install)*
* `dist/`                       Production version of the site *(added after build)*
* `src/`                        Development version of the site
* `src/data/`                   Hardcoded data
* `src/images/`                 Images used throughout the site
* `src/scripts/`                Site scripts and 3rd party libraries
* `src/scripts/collections`     Backbone Collections
* `src/scripts/helpers`         Helpers for Handlebars, Backbone, and generic code
* `src/scripts/models`          Backbone Models
* `src/scripts/modules`         Self-contained, reusable Modules used to construct pages
* `src/scripts/pages`           Backbone Views representing an entire page (or the entire viewport)
* `src/scripts/config.js`       Require.js configuration
* `src/scripts/loader.coffee`   App loader, responsible for setting up global listeners
* `src/scripts/main.js`         Initial script called by Requirejs
* `src/scripts/router.coffee`   Backbone Router
* `src/scripts/session.coffee`  Session state singleton (Backbone Model)
* `src/scripts/settings.js`     Global application config settings (remains in place after build)
* `src/styles/`                 App-specific LESS variables and mixins
* `src/index.html`              App's HTML Page
* `test/`                       Unit tests

# Using Docker

## Install Docker and Docker Compose

Follow the instructions to install [Docker](https://docs.docker.com/install/).

Follow the instructions to install [Docker Compose](https://docs.docker.com/compose/install/).

## Run Docker Compose

    $ docker-compose up -d

## Some notes on using webview with Docker

The nginx and application configurations are automatically generated from environnment variables when using Docker. One can take a glance at the used environment variables in [this file](https://github.com/openstax/webview/blob/master/.dockerfiles/docker-entrypoint.sh). Take special care when assigning these variables that `FE_ARCHIVE_HOST`, `OPENSTAX_HOST`, `LEGACY_HOST`, and `EXERCISE_HOST` must all be able to be resolved by the frontend client. `ARCHIVE` on the other hand, must be able to be resolved by the webview Docker container. For example, if one has archive running in Docker Compose with webview then they could assign `ARCHIVE` like so:
```
ARCHIVE=archive  # the archive service is called 'archive'
ARCHIVE_PORT=6543  # the open port in the archive container - NOT the docker host
```
But could not assign `FE_ARCHIVE_HOST` to the same values. `FE_ARCHIVE_HOST` would need to be assigned to the host name and port exposed on the docker host, instead.

# Installing on Ubuntu 16.04

* Install node 6.9.1.
   * It must be downloaded from the Node JS web site - `https://nodejs.org/dist/v6.9.1/`
   * Unzip the tar ball into a directory
   * Create symlinks to node in the expected locations
      * `ln -sf <YOUR_FOLDER>/bin/node /usr/bin/node`
      * `ln -sf <YOUR_FOLDER>/bin/node /usr/bin/nodejs`
   * Test installation
      - `node -v`
* Install yarn
   * Follow instructions at `https://yarnpkg.com/lang/en/docs/install/#debian-stable`
* Follow Webview installation instructions in README
* Install nginx
   * `sudo apt-get update`
   * `sudo apt-get install nginx`
* Create self signed cert. This will result in 2 files(.key and .cert) created in the directory the command below is run in.
```
   openssl req -x509 -out localhost.crt -keyout localhost.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=localhost' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```
* Copy the Key and Cert files to nginx config location if they were not created there - `webview/conf`
* Update nginx config to use HTTPS - `nginx-dev.conf`
```
      server {
        listen 8000;
        listen 443 ssl;
        ssl_certificate localhost.crt;
        ssl_certificate_key localhost.key;
        root src;
```
* Start server - `sudo ./script/start`

# License

This software is subject to the provisions of the GNU Affero General Public License Version 3.0 (AGPL). See license.txt for details. Copyright (c) 2013 Rice University.
