## Spring Boot Rest CRUD API example

In this backend project, we’re gonna build a Spring Boot Rest CRUD API example with Maven that use Spring Data JPA to
interact with PostgreSQL database.

We will build a Spring Boot JPA Rest CRUD API for a Tutorial application in that:

* Each Tutorial has id, title, description, published status.
* APIs help to create, retrieve, update, delete Tutorials.
* APIs also support custom finder methods such as find by published status or by title.

These are APIs that we need to provide:

* POST ```/tutorials``` — create new Tutorial
* GET ```/tutorials``` — retrieve all Tutorials
* GET ```/tutorials/:id``` — retrieve a Tutorial by ```:id```
* PUT ```/tutorials/:id``` — update a Tutorial by ```:id```
* DELETE ```/tutorials/:id``` — delete a Tutorial by ```:id```
* DELETE ```/tutorials``` — delete all Tutorials
* GET ```/tutorials/published``` — find all published Tutorials
* GET ```/tutorials?title=[keyword]``` — find all Tutorials which title contains keyword

- We make CRUD operations & finder methods with Spring Data JPA’s JpaRepository.
- The database could be PostgreSQL or MySQL depending on the way we configure project dependency & datasource.

### Technology

***

* Java 21
* Spring Boot 4 (with Spring Web MVC, Spring Data JPA)
* PostgreSQL
* Maven

### Run & Test

***

* Create new Tutorial

![POST new.png](Screenshot/POST%20new.png)

* Get all Tutorials

![GET all.png](Screenshot/GET%20all.png)

* Get a Tutorial by Id

![GET by Id.png](Screenshot/GET%20by%20Id.png)

* Find all published Tutorials

![GET published.png](Screenshot/GET%20published.png)

* Find all Tutorials which title contains ‘Test’

![GET find with title.png](Screenshot/GET%20find%20with%20title.png)

* Delete a Tutorial

![DELETE by Id.png](Screenshot/DELETE%20by%20Id.png)

* Delete all Tutorials

![DELETE all.png](Screenshot/DELETE%20all.png)
