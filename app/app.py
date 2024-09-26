from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import uuid
import logging

# Initialize Flask app and database
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:password@postgres/messages_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

migrate = Migrate(app, db)

# Define the Account model (1-to-many with Message)
class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    account_id = db.Column(db.String(50), nullable=False)
    message_id = db.Column(db.String(36), unique=True, nullable=False, default=str(uuid.uuid4()))
    sender_number = db.Column(db.String(15), nullable=False)
    receiver_number = db.Column(db.String(15), nullable=False)

# Logging setup
logging.basicConfig(level=logging.INFO)
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# Route: Get messages by account_id
@app.route('/get/messages/<account_id>', methods=['GET'])
def get_messages(account_id):
    try:
        messages = Message.query.filter_by(account_id=account_id).all()
        if not messages:
            return jsonify({"error": "No messages found for this account"}), 404
        return jsonify([{
            "account_id": msg.account_id,
            "message_id": msg.message_id,
            "sender_number": msg.sender_number,
            "receiver_number": msg.receiver_number
        } for msg in messages]), 200
    except Exception as e:
        app.logger.error(f"Error fetching messages for account {account_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

# Route: Create a message
@app.route('/create', methods=['POST'])
def create_message():
    data = request.get_json()
    try:
        new_message = Message(
            account_id=data['account_id'],
            message_id=str(uuid.uuid4()),
            sender_number=data['sender_number'],
            receiver_number=data['receiver_number']
        )
        db.session.add(new_message)
        db.session.commit()
        return jsonify({"message": "Message created successfully"}), 201
    except Exception as e:
        app.logger.error(f"Error creating message: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

# Route: Search messages
@app.route('/search', methods=['GET'])
def search_messages():
    try:
        message_ids = request.args.get('message_id')
        sender_numbers = request.args.get('sender_number')
        receiver_numbers = request.args.get('receiver_number')
        query = Message.query
        if message_ids:
            message_ids_list = message_ids.strip('"').split(',')
            query = query.filter(Message.message_id.in_(message_ids_list))
        if sender_numbers:
            query = query.filter(Message.sender_number.in_(sender_numbers.strip('"').split(',')))
        if receiver_numbers:
            query = query.filter(Message.receiver_number.in_(receiver_numbers.strip('"').split(',')))

        messages = query.all()
        return jsonify([{
            "account_id": msg.account_id,
            "message_id": msg.message_id,
            "sender_number": msg.sender_number,
            "receiver_number": msg.receiver_number
        } for msg in messages]), 200
    except Exception as e:
        app.logger.error(f"Error searching messages: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500
    


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify(status="OK"), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)