### Simple CRUD HTTP Client using Axios

Axios is a promise-based HTTP Client JavaScript library for Node.js and Browser. In this fronted project, we will create examples that use Axios to make **Get/Post/Put/Delete** request. The final section shows a simple Axios HTTP Client to interact with Rest API.

This Axios Client works with the following Web API:

* POST ```/api/tutorials``` — create new Tutorial
* GET ```/api/tutorials``` — retrieve all Tutorials
* GET ```/api/tutorials/:id``` — retrieve a Tutorial by ```:id```
* PUT ```/api/tutorials/:id``` — update a Tutorial by ```:id```
* DELETE ```/api/tutorials/:id``` — delete a Tutorial by ```:id```
* GET ```/api/tutorials?title=[keyword]``` — find all Tutorials which title contains keyword

### Install Axios

***

We can add Axios to our project/code with one of following simple ways:

* npm: ```npm install axios```
* bower: ```bower install axios```
* yarn: ```yarn add axios```
* CDN: ```<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>```
* Or: ```<script src="https://unpkg.com/axios/dist/axios.min.js"></script>```
