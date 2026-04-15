import os
import logging
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


@app.route("/")
def index():
    return jsonify(
        message="Hello from the People Assignment API",
        environment=os.getenv("ENVIRONMENT", "local"),
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@app.route("/health")
def health():
    return jsonify(status="healthy"), 200


@app.route("/ready")
def ready():
    return jsonify(status="ready"), 200


@app.errorhandler(404)
def not_found(_error):
    return jsonify(error="Not found"), 404


@app.errorhandler(500)
def internal_error(_error):
    logger.exception("Internal server error")
    return jsonify(error="Internal server error"), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
