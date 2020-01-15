FROM python:3

RUN pip install checkov

ADD entrypoint /entrypoint

RUN chmod 0755 /entrypoint

ENTRYPOINT ["/entrypoint"]

CMD ["--help"]
