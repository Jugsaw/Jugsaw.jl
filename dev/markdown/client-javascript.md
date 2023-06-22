
<a id='Javascript-Client'></a>

<a id='Javascript-Client-1'></a>

# Javascript Client


<a id='Get-started-by-example'></a>

<a id='Get-started-by-example-1'></a>

## Get started by example


To complete your first Jugsaw function call, please copy-paste the following code into an `.html` file, and open it with a browser. Tested browsers are: Chrome and Firefox.


```html
<html>
  <head>
  <!-- include the jugsaw library -->
  <script type="text/javascript" src="https://cdn.jsdelivr.net/gh/Jugsaw/Jugsaw/src/js/jugsawirparser.js"></script>
  </head>
  <body>
    <input id="jugsaw-input" type="text"/>
    <button id="jugsaw-submit">submit</button>
    <div id="jugsaw-output"></div>
    <!-- The function call -->
    <script>
      /* 1. Define the client context.
        In a client context, you can specify configurations about the endpoint that providing computing services.
        Here, we choose the official Jugsaw endpoint. For debugging a local Jugsaw application, the default endpoint is "http://0.0.0.0:8088".
      */
      const context = new ClientContext({endpoint:"https://api.jugsaw.co"})

      /* 2. Fetch a Jugsaw app.
        A Jugsaw app contains a list of functions and their using cases.
        Here, we use the "helloworld" application as an example.
        More applications could be found in the [Jugsaw website](https://apps.jugsaw.co).
        The list of available functions are specified on the web-pages.
      */
      const app_promise = request_app(context, "helloworld")

      /* 3. Launches a function call and render output.
        A function call is launched with the `app.call` function.
        The first argument is the function name.
        Since a function may support multiple *input patterns*, `app.call` takes a second argument `0` to choose the first registered implementation of the `greet` function.
        The fourth and fifth arguments are `args` and `kwargs` specified as lists.
        To get help on this function, please refer the [application detail page](https://apps.jugsaw.co/helloworld/details) on the Jugsaw website.
        The return value is a `Promise` object, with which you can render the output.
      */
      const input = document.getElementById("jugsaw-input")
      const output = document.getElementById("jugsaw-output")
      const submit = document.getElementById("jugsaw-submit")
      submit.addEventListener('click', ()=>{
        app_promise.then(app=>app.call("greet", 0, [input.value], [])).then(x=>{output.innerHTML=document.createTextNode(x)})
      }
    )
    </script>
  </body>
</html>
```


<a id='Advanced-topics'></a>

<a id='Advanced-topics-1'></a>

## Advanced topics


The following HTML headers might be helpful for web page developers.


```html
<head>
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/Jugsaw/Jugsaw/src/js/jugsawirparser.js"></script>
<!-- rendering the markdown block -->
<script type="module" src="https://md-block.verou.me/md-block.js"></script>
<!-- code block highlight -->
<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/10.0.0/highlight.min.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/10.0.0/languages/julia.min.js"></script>
<script>
hljs.initHighlightingOnLoad();
</script>
<!-- dark theme of the code block -->
<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/a11y-dark.min.css">

<!-- math equation rendering -->
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  extensions: ["tex2jax.js"],
  tex2jax: {
    inlineMath: [["$","$"]],
    displayMath: [['$$','$$']],
    },
  asciimath2jax: {delimiters: []},
  CommonHTML: {
    scale: 120
  }
});
</script>
<script type="text/javascript" async src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/latest.js?config=TeX-MML-AM_CHTML"></script>
</head>
```


For a thorough example, please check the [jugsaw debugger page](https://github.com/Jugsaw/Jugsaw/blob/main/src/js/jugsawdebug.html).

