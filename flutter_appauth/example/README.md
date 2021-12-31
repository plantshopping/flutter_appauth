## IceDiary Setup Guide

- I had to go to Auth0 Dashboard, select my native application, and enable refresh token expiration. Before I was getting only a short version of the access token.
- I also had to send additionalParameters with audience when getting the token https://icediaryapi.azurewebsites.net/api (the api's identifier)
- https://auth0.com/blog/build-flutter-wishlist-app-with-secure-api-part-3/#Implementing-Sign-Out
