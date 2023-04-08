FROM python:3.10

COPY . /jugsaw

WORKDIR /jugsaw/example/generic_tensornetwork/service

RUN pip config set global.index-url https://mirrors.bfsu.edu.cn/pypi/web/simple \
    && pip install poetry \
    && poetry install

ENTRYPOINT [ "poetry", "run" ]

CMD ["uvicorn", "main:server", "--host", "0.0.0.0"]
