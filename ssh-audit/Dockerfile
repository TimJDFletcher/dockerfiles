FROM python:3

RUN git clone https://github.com/arthepsy/ssh-audit /opt/ssh-audit

ENTRYPOINT ["/opt/ssh-audit/ssh-audit.py"]
CMD ["--help"]