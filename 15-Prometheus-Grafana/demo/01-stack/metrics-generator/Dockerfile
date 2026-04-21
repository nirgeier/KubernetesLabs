FROM python:3.11-slim
WORKDIR /app
COPY app.py /app/
RUN pip install prometheus-client
EXPOSE 8000
CMD ["python", "app.py"]
