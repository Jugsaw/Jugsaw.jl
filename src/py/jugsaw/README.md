# jugsaw

Jugsaw python client.

## The tab completion

Let `app` be the Jugsaw app that loaded to your ipython REPL or Jupyter notebook. To check available functions, just type

```python
app.<TAB>
``

It the above code does not work, this may be due to a [open issue](https://github.com/ipython/ipython/issues/11856) that related to Jedi. You can fix it by pasting the following code into your ipython REPL or Jupyter notebook.

```ipython
%config IPCompleter.use_jedi = False
```
