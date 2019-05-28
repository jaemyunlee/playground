FROM python:3.6.8-alpine3.9

COPY scripts/ /app/
WORKDIR /app
RUN pip install -r requirements.txt
RUN apk add bash
RUN chmod +x wait-for-resource.sh
CMD ["python", "create-resource.py"]