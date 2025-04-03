FROM debian:12-slim
RUN apt-get update && apt-get install -y sl
CMD /usr/games/sl
