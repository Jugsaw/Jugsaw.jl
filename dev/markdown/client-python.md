
<a id='Python-Client'></a>

<a id='Python-Client-1'></a>

# Python Client


<a id='Install'></a>

<a id='Install-1'></a>

## Install


```bash
pip install jugsaw
```


<a id='Get-started-by-example'></a>

<a id='Get-started-by-example-1'></a>

## Get started by example


To complete your first Jugsaw function call, please copy-paste the following code into a python REPL.


```python
import jugsaw
context = jugsaw.ClientContext(endpoint="app.jugsaw.co")
app = jugsaw.request_app(context, "helloworld")
lazyreturn = app.greet[0]("Jugsaw")
result = lazyreturn()   # fetch result
```


This example will be explained line by line in the following.


1. The first line imports the `jugsaw` python client.
2. The second line defines the client context.


```python
context = jugsaw.ClientContext(endpoint="https://api.jugsaw.co")
```


In a client context, you can specify the endpoint that providing computing services. Here, we choose the official Jugsaw endpoint. For debugging a local Jugsaw application, the default endpoint is "http://0.0.0.0:8088".


3. The third line fetches the application.


```python
app = jugsaw.request_app(context, "helloworld")
```


Here, we use the "helloworld" application as an example. A Jugsaw app contains a list of functions and their using cases. One can type `dir(app)` in a python REPL to get a list of available functions. More applications could be found in the [Jugsaw website](https://apps.jugsaw.co).


4. The fourth line launches a function call request to the remote.


```python
lazyreturn = app.greet[0]("Jugsaw")
```


Since a function may support multiple *input patterns*, we use `app.greet[0]` to select the first registered implementation of the `greet` function. The indexing can be ommited in this case because the `greet` function here has only one implementation, i.e. `lazyreturn = app.greet("Jugsaw")` is also correct here. To get help on this function, just type `help(app.greet)` in a python REPL. Alternatively, help message and *input patterns* could be found on the [application detail page](https://apps.jugsaw.co/helloworld/details) on the Jugsaw website. The return value is a `LazyReturn` object that containing the job id information.


5. The last line fetches the results.


```python
result = lazyreturn()   # fetch result
```

