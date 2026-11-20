# Dockerfile for the challenger image (based on anubis) wrapped with its configuration
FROM ghcr.io/techarohq/anubis:v1.28.2
EXPOSE 8923

# No --chmod here: it would also apply to the parent dirs BuildKit creates
# (/data, /data/cfg), stripping their execute bit and making the policy
# unreadable for the runtime user. Source file mode (644) is preserved instead.
COPY --chown=1000:1000 botPolicy.yaml /data/cfg/botPolicy.yaml

ENV BIND=":8923"
ENV DIFFICULTY=5
ENV POLICY_FNAME="/data/cfg/botPolicy.yaml"
ENV TARGET="http://backend:8000"