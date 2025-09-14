import razorpay
import os
from flask import Flask, request, jsonify
from flask import send_from_directory
from flask_cors import CORS
import pymysql
from dotenv import load_dotenv
import re
import spacy
from rapidfuzz import fuzz, process
from transformers import pipeline
from google.cloud import speech_v1p1beta1 as speech
import io
import assemblyai as aai
import json
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import jwt

load_dotenv()

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'super-secret-key')

aai.settings.api_key = os.getenv("ASSEMBLYAI_API_KEY")
GOOGLE_CLOUD_SPEECH_KEY_PATH = os.getenv("GOOGLE_CLOUD_SPEECH_KEY_PATH")

# Razorpay test credentials (replace with your own test keys)
RAZORPAY_KEY_ID = os.getenv('RAZORPAY_KEY_ID', 'rzp_test_YourKeyHere')
RAZORPAY_KEY_SECRET = os.getenv('RAZORPAY_KEY_SECRET', 'YourSecretHere')
razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))

# Razorpay order creation endpoint
@app.route('/create_razorpay_order', methods=['POST'])
def create_razorpay_order():
    data = request.get_json()
    amount = int(float(data.get('amount', 0)) * 100)  # Razorpay expects amount in paise
    currency = data.get('currency', 'INR')
    receipt = data.get('receipt', f'receipt_{datetime.now().timestamp()}')
    try:
        order = razorpay_client.order.create({
            'amount': amount,
            'currency': currency,
            'receipt': receipt,
            'payment_capture': 1
        })
        print('Razorpay order response:', order)
        return jsonify({'order': order}), 200
    except Exception as exc:
        import traceback
        print('Razorpay order error:', exc)
        traceback.print_exc()
        return jsonify({'error': str(exc)}), 500

import os
from flask import Flask, request, jsonify
from flask import send_from_directory
from flask_cors import CORS
import pymysql
from dotenv import load_dotenv
import re
import spacy
from rapidfuzz import fuzz, process
from transformers import pipeline
from google.cloud import speech_v1p1beta1 as speech
import io
import assemblyai as aai
import json
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import jwt

load_dotenv()

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'super-secret-key')

aai.settings.api_key = os.getenv("ASSEMBLYAI_API_KEY")
GOOGLE_CLOUD_SPEECH_KEY_PATH = os.getenv("GOOGLE_CLOUD_SPEECH_KEY_PATH")

# Load spaCy English model
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Downloading spaCy model 'en_core_web_sm'...")
    spacy.cli.download("en_core_web_sm")
    nlp = spacy.load("en_core_web_sm")

intent_classifier = pipeline("zero-shot-classification", model="facebook/bart-large-mnli")

def detect_intent_hf(speech_text):
    candidate_intents = [
        "split bill",
        "apply discount",
        "associate customer",
        "add item",
        "show total",
        "clear bill",
        "generate receipt"
    ]
    result = intent_classifier(speech_text, candidate_intents)
    return result['labels'][0] if result['scores'][0] > 0.5 else None

db_config = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'db': os.getenv('DB_NAME', 'srbs_db'),
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection():
    return pymysql.connect(**db_config)

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'x-access-token' in request.headers:
            token = request.headers['x-access-token']
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            conn = get_db_connection()
            with conn.cursor() as cursor:
                cursor.execute("SELECT id, username, role FROM users WHERE id = %s", (data['user_id'],))
                current_user = cursor.fetchone()
            if not current_user:
                return jsonify({'message': 'User not found!'}), 401
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired!'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token is invalid!'}), 401
        except Exception as exc:
            print(f"Token error: {exc}")
            return jsonify({'message': 'Token error!'}), 401
        finally:
            if conn: conn.close()
        return f(current_user, *args, **kwargs)
    return decorated

@app.route('/login', methods=['POST'])
def login_user():
    auth = request.get_json()
    username = auth.get('username')
    password = auth.get('password')
    if not username or not password:
        return jsonify({'message': 'Username and password are required!'}), 400
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, username, password_hash, role FROM users WHERE username = %s", (username,))
            user = cursor.fetchone()
            if not user or not check_password_hash(user['password_hash'], password):
                return jsonify({'message': 'Invalid credentials!'}), 401
            token = jwt.encode({
                'user_id': user['id'],
                'role': user['role'],
                'exp': datetime.utcnow() + timedelta(minutes=60)
            }, app.config['SECRET_KEY'], algorithm="HS256")
            return jsonify({'token': token, 'role': user['role']}), 200
    except Exception as exc:
        print(f"Error logging in user: {exc}")
        return jsonify({'message': 'Internal server error.'}), 500
    finally:
        if conn: conn.close()

@app.route('/products', methods=['GET'])
@token_required
def get_products(current_user):
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT product_id, product_name, category, price, gst_rate, stock_quantity FROM products ORDER BY product_name")
            products = cursor.fetchall()
            for product in products:
                product['price'] = float(product['price'])
                product['gst_rate'] = float(product['gst_rate'])
        return jsonify({'products': products})
    except Exception as exc:
        print(f"Database error fetching products: {exc}")
        return jsonify({'error': str(exc)}), 500
    finally:
        if conn: conn.close()

@app.route('/analytics/sales_summary', methods=['GET'])
def sales_summary():
    period = request.args.get('period', 'daily')
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            now = datetime.now()
            if period == 'daily':
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            elif period == 'weekly':
                start = now - timedelta(days=now.weekday())
                start = start.replace(hour=0, minute=0, second=0, microsecond=0)
            elif period == 'monthly':
                start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            else:
                return jsonify({'error': 'Invalid period'}), 400
            cursor.execute("SELECT COUNT(*) AS total_bills, SUM(final_total_amount) AS total_revenue FROM bills WHERE bill_date >= %s", (start,))
            result = cursor.fetchone()
            return jsonify({
                'period': period,
                'total_bills': int(result['total_bills']) if result['total_bills'] else 0,
                'total_revenue': float(result['total_revenue']) if result['total_revenue'] else 0.0
            })
    except Exception as exc:
        print(f"Error in sales_summary: {exc}")
        return jsonify({'error': str(exc)}), 500
    finally:
        if conn: conn.close()

@app.route('/analytics/top_products', methods=['GET'])
def top_products():
    limit = int(request.args.get('limit', 5))
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT p.product_name, SUM(bi.quantity) AS total_sold
                FROM bill_items bi
                JOIN products p ON bi.product_id = p.product_id
                GROUP BY p.product_name
                ORDER BY total_sold DESC
                LIMIT %s
            """, (limit,))
            products = cursor.fetchall()
            return jsonify({'top_products': products})
    except Exception as exc:
        print(f"Error in top_products: {exc}")
        return jsonify({'error': str(exc)}), 500
    finally:
        if conn: conn.close()

@app.route('/transcribe_audio', methods=['POST'])
def transcribe_audio():
    # Example: Use AssemblyAI for speech-to-text
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400
    audio_file = request.files['audio']
    language = request.form.get('language', 'en')
    try:
        transcript = None
        aai_transcriber = aai.Transcriber()
        transcript_obj = aai_transcriber.transcribe(audio_file)
        transcript = transcript_obj.text if transcript_obj else None
        if not transcript:
            return jsonify({'error': 'Transcription failed'}), 500
        # Optionally, run NLP intent detection
        intent = detect_intent_hf(transcript)

        # Advanced item extraction using spaCy and DB lookup
        bill = []
        word_to_num = {'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5}
        doc = nlp(transcript)
        # Extract item and quantity pairs
        for ent in doc.ents:
            if ent.label_ == 'CARDINAL':
                qty_text = ent.text.lower()
                qty = word_to_num.get(qty_text, None)
                if qty is None:
                    try:
                        qty = int(qty_text)
                    except:
                        qty = 1
                # Find the next noun after the quantity
                for token in doc:
                    if token.text == ent.text:
                        # Look for next noun
                        next_noun = next((t for t in doc[token.i+1:] if t.pos_ == 'NOUN'), None)
                        if next_noun:
                            item_name = next_noun.text
                            # Fuzzy match against all product names in DB
                            conn = get_db_connection()
                            try:
                                with conn.cursor() as cursor:
                                    cursor.execute("SELECT product_id, product_name, price, gst_rate FROM products")
                                    products = cursor.fetchall()
                                    product_names = [p['product_name'] for p in products]
                                    # Use token_set_ratio for better tolerance to misspellings and partial matches
                                    result = process.extractOne(item_name, product_names, scorer=fuzz.token_set_ratio)
                                    if result:
                                        match, score, idx = result
                                        if score >= 65:
                                            product = products[idx]
                                            bill.append({
                                                'product_id': product['product_id'],
                                                'name': product['product_name'],
                                                'quantity': qty,
                                                'price': float(product['price']),
                                                'gst_rate': float(product['gst_rate'])
                                            })
                                        else:
                                            # Fallback: try partial match for multi-word products
                                            partial_matches = [p for p in products if item_name.lower() in p['product_name'].lower()]
                                            if partial_matches:
                                                product = partial_matches[0]
                                                bill.append({
                                                    'product_id': product['product_id'],
                                                    'name': product['product_name'],
                                                    'quantity': qty,
                                                    'price': float(product['price']),
                                                    'gst_rate': float(product['gst_rate'])
                                                })
                                            else:
                                                bill.append({'name': item_name, 'quantity': qty, 'price': 0, 'gst_rate': 0})
                                    else:
                                        bill.append({'name': item_name, 'quantity': qty, 'price': 0, 'gst_rate': 0})
                            except Exception as exc:
                                print(f"DB lookup error: {exc}")
                            finally:
                                if conn: conn.close()
                        break
        return jsonify({'transcription': transcript, 'intent': intent, 'bill': bill})
    except Exception as exc:
        print(f"Error in transcribe_audio: {exc}")
        return jsonify({'error': str(exc)}), 500

@app.route('/process_text_for_bill', methods=['POST'])
def process_text_for_bill():
    data = request.get_json()
    text = data.get('text', '')
    bill = data.get('bill', [])
    language = data.get('language', 'en')
    # Example: Use NLP to extract items, quantities, actions
    try:
        doc = nlp(text)
        # Dummy logic: just echo back
        confirmation = f"Processed: {text}"
        return jsonify({'bill': bill, 'confirmation': confirmation})
    except Exception as exc:
        print(f"Error in process_text_for_bill: {exc}")
        return jsonify({'error': str(exc)}), 500

@app.route('/generate_receipt', methods=['POST'])
def generate_receipt():
    data = request.get_json()
    bill = data.get('bill', [])
    # Calculate total_amount from bill items
    total_amount = 0
    for item in bill:
        price = item.get('price', 0)
        qty = item.get('quantity', 1)
        total_amount += price * qty
    # Example: Save bill to DB, generate receipt
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Insert bill
            bill_date = datetime.now()
            cursor.execute("INSERT INTO bills (bill_date, final_total_amount) VALUES (%s, %s)", (bill_date, total_amount))
            bill_id = cursor.lastrowid
            # Insert bill items
            for item in bill:
                product_id = item.get('product_id')
                if product_id is not None:
                    cursor.execute("INSERT INTO bill_items (bill_id, product_id, quantity, price_at_sale) VALUES (%s, %s, %s, %s)",
                                   (bill_id, product_id, item.get('quantity'), item.get('price')))
                else:
                    print(f"Skipping item with missing product_id: {item}")
            conn.commit()
            receipt = {
                'id': bill_id,
                'bill_date': bill_date.strftime('%Y-%m-%d %H:%M:%S'),
                'items': bill,
                'total_amount': total_amount,
                'subtotal_amount': total_amount,  # For demo
                'total_tax_amount': 0.0  # For demo
            }
            return jsonify({'receipt': receipt})
    except Exception as exc:
        print(f"Error in generate_receipt: {exc}")
        return jsonify({'error': str(exc)}), 500
    finally:
        if conn: conn.close()


# Add the default route at the end of the file

# Serve index.html at root
@app.route("/")
def index():
    return send_from_directory('../frontend', 'index.html')

# Serve static files (CSS, JS, images)
@app.route('/<path:filename>')
def static_files(filename):
    return send_from_directory('../frontend', filename)

if __name__ == '__main__':
    app.run(debug=True)
