FROM alpine:latest
RUN echo "Hello Docker Reginstry!" > /hello.txt
CMD ["cat", "/hello.txt"]
