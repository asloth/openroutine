# syntax=docker/dockerfile:1
# Serves the public site (home page and privacy policy) as a container, for the
# Dokploy app at https://openroutine.sara.coffee. Build it from the repository
# root: docker build -f site/Dockerfile .
FROM ruby:3.3-alpine AS build
# The primer theme reads repository details through jekyll-github-metadata,
# which shells out to git.
RUN apk add --no-cache build-base git \
  && gem install --no-document jekyll:4.3.4 jekyll-theme-primer:0.6.0 jekyll-seo-tag:2.8.0 jekyll-github-metadata:2.16.1 kramdown-parser-gfm webrick
WORKDIR /src
COPY site/ site/
COPY docs/privacy-policy.md docs/privacy-policy.md
# Same front matter the Pages workflow adds, so both copies render alike.
RUN { \
    printf -- '---\ntitle: Privacy policy\npermalink: /privacy/\npath: docs/privacy-policy.md\n---\n\n'; \
    cat docs/privacy-policy.md; \
  } > site/privacy.md
# GitHub Pages applies the theme layout and these plugins on its own, and it
# serves the site under /openroutine. This build-only config spells that out
# for a site at the domain root, so site/_config.yml stays as Pages expects.
COPY <<EOF /tmp/build.yml
url: https://openroutine.sara.coffee
baseurl: ""
markdown: kramdown
kramdown:
  input: GFM
plugins:
  - jekyll-seo-tag
  - jekyll-github-metadata
github:
  source:
    branch: main
    path: /
defaults:
  - scope:
      path: ""
    values:
      layout: default
EOF
ENV PAGES_REPO_NWO=asloth/openroutine JEKYLL_ENV=production
RUN jekyll build --source site --destination /out --config site/_config.yml,/tmp/build.yml

FROM nginx:1.27-alpine
COPY --from=build /out /usr/share/nginx/html
