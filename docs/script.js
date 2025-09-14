// Razorpay payment integration for payment.html
document.addEventListener('DOMContentLoaded', () => {
    if (document.body.classList.contains('payment-page')) {
        const payBtn = document.getElementById('payWithRazorpay');
        const statusDiv = document.getElementById('razorpayStatus');
        // Get total amount from localStorage (set during receipt)
        let receiptDetails = JSON.parse(localStorage.getItem('receiptDetails'));
        let amount = receiptDetails ? receiptDetails.total_amount : 100; // fallback to 100 if not found
        payBtn.addEventListener('click', async () => {
            statusDiv.textContent = 'Creating order...';
            try {
                const response = await fetch(`${backendUrl}/create_razorpay_order`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ amount: amount, currency: 'INR', receipt: receiptDetails ? receiptDetails.id : 'test_receipt' })
                });
                const data = await response.json();
                if (data.error) {
                    statusDiv.textContent = 'Order creation failed: ' + data.error;
                    return;
                }
                const order = data.order;
                const options = {
                    key: 'rzp_test_YourKeyHere', // Replace with your Razorpay test key
                    amount: order.amount,
                    currency: order.currency,
                    name: 'Punjabi Cafe',
                    description: 'Bill Payment',
                    order_id: order.id,
                    handler: function (response){
                        statusDiv.textContent = 'Payment successful! Payment ID: ' + response.razorpay_payment_id;
                    },
                    prefill: {
                        name: 'Test User',
                        email: 'test@example.com',
                        contact: '9999999999'
                    },
                    theme: {
                        color: '#F37254'
                    }
                };
                const rzp = new window.Razorpay(options);
                rzp.open();
            } catch (err) {
                statusDiv.textContent = 'Payment error: ' + err;
            }
        });
    }
});
let mediaRecorder;
let audioChunks = [];
let isRecording = false;
let billItems = [];
// availableProducts is no longer used by frontend directly as per new UI

const backendUrl = 'http://127.0.0.1:5000';

// Initial setup
document.addEventListener('DOMContentLoaded', () => {
    if (document.body.classList.contains('language-selection-page')) {
        const startBillingButton = document.getElementById('startBilling');
        const languageSelect = document.getElementById('language-select');

        startBillingButton.addEventListener('click', () => {
            localStorage.setItem('selectedLanguage', languageSelect.value);
            document.body.classList.add('page-exit-active');
            setTimeout(() => {
                window.location.href = 'bill.html';
            }, 500); // Match animation duration
        });
    } else if (document.body.classList.contains('bill-page')) {
        document.body.classList.add('page-enter-active'); // Apply enter animation
        const startRecognitionButton = document.getElementById('startRecognition');
        const speechOutputParagraph = document.getElementById('speechOutput');
        const systemFeedbackParagraph = document.getElementById('systemFeedback');
        const statusMessageDiv = document.getElementById('statusMessage');
        const itemList = document.getElementById('itemList');
        const totalAmountSpan = document.getElementById('totalAmount');
        const clearBillButton = document.getElementById('clearBill');
        const generateReceiptButton = document.getElementById('generateReceipt');
        const billSection = document.querySelector('.current-bill-section');
        const processingAnimationDiv = document.getElementById('processingAnimation');

        const selectedLanguage = localStorage.getItem('selectedLanguage') || 'en-US';
        // You might want to display the selected language on the bill page
        // For now, it's just used in sendAudioToBackend

        renderBillSection(); // Ensure bill section is visible initially
        updateStatusMessage(true, "Speech recognition supported. Ready to start!");

        startRecognitionButton.addEventListener('click', async () => {
            if (!isRecording) {
                await startRecording();
            } else {
                stopRecording();
            }
        });

        clearBillButton.addEventListener('click', () => {
            billItems = [];
            updateBillDisplay();
            systemFeedbackParagraph.textContent = 'Bill cleared!';
            updateStatusMessage(true, "Bill cleared. Ready for new input!");
        });

        generateReceiptButton.addEventListener('click', async () => {
            if (billItems.length === 0) {
                systemFeedbackParagraph.textContent = 'Add items to the bill before generating a receipt.';
                updateStatusMessage(false, "Cannot generate receipt: No items in bill.");
                return;
            }

            systemFeedbackParagraph.textContent = 'Generating receipt...';
            updateStatusMessage(true, "Generating receipt...");
            try {
                const response = await fetch(`${backendUrl}/generate_receipt`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ bill: billItems, total_amount: parseFloat(totalAmountSpan.textContent) }),
                });
                const data = await response.json();

                if (data.error) {
                    systemFeedbackParagraph.textContent = `Receipt Error: ${data.error}`;
                    updateStatusMessage(false, `Receipt generation failed: ${data.error}`);
                } else {
                    localStorage.setItem('receiptDetails', JSON.stringify(data.receipt));
                    document.body.classList.add('page-exit-active');
                    setTimeout(() => {
                        window.location.href = 'receipt.html';
                    }, 500); // Match animation duration
                }
            } catch (error) {
                console.error('Error generating receipt:', error);
                systemFeedbackParagraph.textContent = 'Network Error or Backend is Down.';
                updateStatusMessage(false, 'Network error or backend is down.');
            }
        });

        async function startRecording() {
            try {
                statusMessageDiv.classList.remove('success-message', 'error-message');
                statusMessageDiv.textContent = '';

                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                mediaRecorder = new MediaRecorder(stream);
                audioChunks = [];
                console.log('MediaRecorder initialized. State:', mediaRecorder.state);

                mediaRecorder.ondataavailable = (event) => {
                    audioChunks.push(event.data);
                    console.log('Audio data available, chunk size:', event.data.size);
                };

                mediaRecorder.onstop = async () => {
                    console.log('MediaRecorder stopped. State:', mediaRecorder.state);
                    const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
                    sendAudioToBackend(audioBlob, selectedLanguage);
                    stream.getTracks().forEach(track => track.stop());
                };

                mediaRecorder.onstart = () => {
                    isRecording = true;
                    startRecognitionButton.innerHTML = '<i class="fas fa-stop"></i> Stop Listening';
                    startRecognitionButton.classList.add('recording');
                    speechOutputParagraph.textContent = 'Recording...';
                    systemFeedbackParagraph.textContent = 'Speak clearly, then click Stop Listening.';
                    updateStatusMessage(true, "Recording in progress...");
                    console.log('Recording started. State:', mediaRecorder.state);
                };
                
                mediaRecorder.onerror = (event) => {
                    console.error('MediaRecorder error:', event.error);
                    systemFeedbackParagraph.textContent = `Recording Error: ${event.error}`;
                    isRecording = false;
                    startRecognitionButton.innerHTML = '<i class="fas fa-microphone"></i> Start Listening';
                    startRecognitionButton.classList.remove('recording');
                    stream.getTracks().forEach(track => track.stop());
                    updateStatusMessage(false, `Microphone Error: ${event.error.name || event.error}`);
                };

                mediaRecorder.start();
            } catch (error) {
                console.error('Error accessing microphone:', error);
                systemFeedbackParagraph.textContent = 'Microphone access denied or not available.';
                updateStatusMessage(false, 'Microphone access denied. Please check browser permissions.');
            }
        }

        function stopRecording() {
            if (mediaRecorder && mediaRecorder.state === 'recording') {
                console.log('Stopping MediaRecorder. State before stop:', mediaRecorder.state);
                mediaRecorder.stop();
                isRecording = false;
                startRecognitionButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
                startRecognitionButton.classList.remove('recording');
                startRecognitionButton.disabled = true; // Disable button while processing
                systemFeedbackParagraph.textContent = 'Sending audio for transcription...';
                updateStatusMessage(true, "Transcribing audio...");
                processingAnimationDiv.style.display = 'flex'; // Show animation
            }
        }

        async function sendAudioToBackend(audioBlob, selectedLanguage) {
            const formData = new FormData();
            formData.append('audio', audioBlob, 'audio.wav');
            formData.append('current_bill', JSON.stringify(billItems)); // Send current bill for context
            formData.append('language', selectedLanguage); // Send selected language
            
            console.log('Preparing to send audio to backend...');
            console.log('AudioBlob size:', audioBlob.size, 'bytes');
            console.log('AudioBlob type:', audioBlob.type);
            
            try {
                const response = await fetch(`${backendUrl}/transcribe_audio`, {
                    method: 'POST',
                    body: formData,
                });
                const data = await response.json();

                if (data.error) {
                    systemFeedbackParagraph.textContent = `Backend Error: ${data.error}`;
                    updateStatusMessage(false, `Transcription failed: ${data.error}`);
                } else {
                    // Extract customer info from transcription if available
                    const transcribedText = data.transcription.toLowerCase();
                    let customerName = null;
                    let customerPhone = null;

                    const associateMatch = transcribedText.match(/(?:associate bill with|for) customer (.+)/);
                    if (associateMatch) {
                        customerName = associateMatch[1].trim();
                        systemFeedbackParagraph.textContent += ` Attempting to associate bill with existing customer: ${customerName}.`;
                    }

                    const newCustomerMatch = transcribedText.match(/new customer (.+) with phone (\d+)/);
                    if (newCustomerMatch) {
                        customerName = newCustomerMatch[1].trim();
                        customerPhone = newCustomerMatch[2].trim();
                        systemFeedbackParagraph.textContent += ` Attempting to create new customer: ${customerName}, Phone: ${customerPhone}.`;
                    }

                    speechOutputParagraph.textContent = `Transcription: "${data.transcription || 'No speech detected.'}"`;
                    billItems = data.bill || []; // Update bill with processed items, fallback to empty array
                    updateBillDisplay();
                    systemFeedbackParagraph.textContent = data.confirmation; // Display confirmation message
                    speak(data.confirmation); // Speak the confirmation message
                    if (data.amount_per_person) {
                        const splitMessage = `Each person owes ₹${data.amount_per_person.toFixed(2)}.`;
                        systemFeedbackParagraph.textContent += ` ${splitMessage}`;
                        speak(splitMessage);
                    }
                    updateStatusMessage(true, "Transcription successful. Bill updated.");

                    // Check for daily sales report command
                    if (data.transcription && data.transcription.toLowerCase().includes("show today's sales report")) {
                        fetchDailySalesReport();
                    }
                }
            } catch (error) {
                console.error('Error sending audio to backend:', error);
                systemFeedbackParagraph.textContent = 'Network Error or Backend is Down.';
                updateStatusMessage(false, 'Network error or backend is down.');
            } finally {
                startRecognitionButton.disabled = false;
                startRecognitionButton.innerHTML = '<i class="fas fa-microphone"></i> Start Listening';
                processingAnimationDiv.style.display = 'none'; // Hide animation
            }
        }

        function speak(text) {
            if ('speechSynthesis' in window) {
                const utterance = new SpeechSynthesisUtterance(text);
                // You can customize voice, pitch, and rate here if needed
                // For example: utterance.voice = speechSynthesis.getVoices()[0];
                // utterance.pitch = 1;
                // utterance.rate = 1;
                speechSynthesis.speak(utterance);
            } else {
                console.warn("Speech Synthesis API not supported in this browser.");
            }
        }

        function updateBillDisplay() {
            itemList.innerHTML = '';
            let total = 0;

            if (billItems.length === 0) {
                itemList.innerHTML = '<li>No items added yet. Use voice commands to add items.</li>';
                totalAmountSpan.textContent = '0';
                return;
            }

            billItems.forEach(item => {
                const listItem = document.createElement('li');
                listItem.textContent = `${item.quantity} x ${item.name} - ₹${(item.price * item.quantity).toFixed(2)}`;
                itemList.appendChild(listItem);
                total += item.price * item.quantity;
            });

            totalAmountSpan.textContent = total.toFixed(0);
        }

        function renderBillSection() {
            // In bill.html, the bill section is always visible
            // No need to hide/show sections as there's no receipt section on this page
        }

        function updateStatusMessage(isSuccess, message) {
            statusMessageDiv.innerHTML = ''; // Clear previous content
            
            const messageContainer = document.createElement('div');
            messageContainer.classList.add('message-container');

            const iconSpan = document.createElement('span');
            iconSpan.classList.add('status-icon');

            const textSpan = document.createElement('span');
            textSpan.classList.add('status-text');
            textSpan.textContent = message;

            if (isSuccess) {
                statusMessageDiv.classList.remove('error-message');
                statusMessageDiv.classList.add('success-message');
                iconSpan.classList.add('fas', 'fa-check-circle');
            } else {
                statusMessageDiv.classList.remove('success-message');
                statusMessageDiv.classList.add('error-message');
                iconSpan.classList.add('fas', 'fa-exclamation-circle');
            }
            
            messageContainer.appendChild(iconSpan);
            messageContainer.appendChild(textSpan);
            statusMessageDiv.appendChild(messageContainer);
        }

    } else if (document.body.classList.contains('receipt-page')) {
        document.body.classList.add('page-enter-active'); // Apply enter animation
        const newBillButton = document.getElementById('newBill');
        const makePaymentButton = document.getElementById('makePayment');
        const receiptIdSpan = document.getElementById('receiptId');
        const receiptDateSpan = document.getElementById('receiptDate');
        const receiptTimeSpan = document.getElementById('receiptTime');
        const receiptItemsTableBody = document.getElementById('receiptItems');
        const receiptTotalAmountBeforeTaxSpan = document.getElementById('receiptTotalAmountBeforeTax');
        const receiptTaxPercentageSpan = document.getElementById('receiptTaxPercentage');
        const receiptTaxSpan = document.getElementById('receiptTax');
        const receiptTotalSpan = document.getElementById('receiptTotal');
        const sundayBuffetAdultsSpan = document.getElementById('sundayBuffetAdults');
        const sundayBuffetChildrenSpan = document.getElementById('sundayBuffetChildren');

        const receiptDetails = JSON.parse(localStorage.getItem('receiptDetails'));
        if (receiptDetails) {
            displayReceipt(receiptDetails);
        } else {
            console.error('No receipt details found in localStorage.');
            // Optionally, redirect back to bill.html or show an error message
        }

        newBillButton.addEventListener('click', () => {
            localStorage.removeItem('receiptDetails'); // Clear receipt details
            document.body.classList.add('page-exit-active');
            setTimeout(() => {
                window.location.href = 'bill.html';
            }, 500); // Match animation duration
        });

        makePaymentButton.addEventListener('click', () => {
            document.body.classList.add('page-exit-active');
            setTimeout(() => {
                window.location.href = 'payment.html';
            }, 500); // Match animation duration
        });

        function displayReceipt(receipt) {
            receiptIdSpan.textContent = receipt.id; // Update receipt ID
            
            // Format date and time
            const billDateTime = new Date(receipt.bill_date);
            if (!isNaN(billDateTime.getTime())) { // Check if the date is valid
                receiptDateSpan.textContent = billDateTime.toLocaleDateString('en-US');
                receiptTimeSpan.textContent = billDateTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
            } else {
                receiptDateSpan.textContent = 'Invalid Date';
                receiptTimeSpan.textContent = 'Invalid Time';
                console.error('Invalid bill_date received:', receipt.bill_date);
            }

            receiptItemsTableBody.innerHTML = ''; // Clear previous items

            receipt.items.forEach(item => {
                const tableRow = document.createElement('tr');
                tableRow.innerHTML = `
                    <td>${item.name}</td>
                    <td>${item.quantity}</td>
                    <td>₹${item.price.toFixed(2)}</td>
                    <td>₹${(item.price * item.quantity).toFixed(2)}</td>
                `;
                receiptItemsTableBody.appendChild(tableRow);
            });

            // Populate summary details
            receiptTotalAmountBeforeTaxSpan.textContent = receipt.subtotal_amount.toFixed(2);
            receiptTaxSpan.textContent = receipt.total_tax_amount.toFixed(2);
            receiptTotalSpan.textContent = receipt.total_amount.toFixed(2);

            // Populate Sunday Buffet details - using static values as per image
            sundayBuffetAdultsSpan.textContent = '850';
            sundayBuffetChildrenSpan.textContent = '500';
            }
    
            // Essential receipt details only
            receiptIdSpan.textContent = receipt.id;
            const billDateTime = new Date(receipt.bill_date);
            receiptDateSpan.textContent = !isNaN(billDateTime.getTime()) ? billDateTime.toLocaleDateString('en-US') : 'Invalid Date';
            receiptTimeSpan.textContent = !isNaN(billDateTime.getTime()) ? billDateTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }) : 'Invalid Time';

            receiptItemsTableBody.innerHTML = '';
            receipt.items.forEach(item => {
                const tableRow = document.createElement('tr');
                tableRow.innerHTML = `
                    <td>${item.name}</td>
                    <td>${item.quantity}</td>
                    <td>₹${item.price.toFixed(2)}</td>
                    <td>₹${(item.price * item.quantity).toFixed(2)}</td>
                `;
                receiptItemsTableBody.appendChild(tableRow);
            });

            receiptTotalAmountBeforeTaxSpan.textContent = receipt.subtotal_amount.toFixed(2);
            receiptTaxSpan.textContent = receipt.total_tax_amount.toFixed(2);
            receiptTotalSpan.textContent = receipt.total_amount.toFixed(2);

            // Hide extra details
            if (typeof sundayBuffetAdultsSpan !== 'undefined') sundayBuffetAdultsSpan.textContent = '';
            if (typeof sundayBuffetChildrenSpan !== 'undefined') sundayBuffetChildrenSpan.textContent = '';

        const languageSelect = document.getElementById('language-select');
        languageSelect.addEventListener('change', (event) => {
            switchLanguage(event.target.value);
        });

        // Initialize language on page load
        const savedLanguage = localStorage.getItem('selectedLanguage') || 'en';
        languageSelect.value = savedLanguage;
        switchLanguage(savedLanguage);

        function switchLanguage(lang) {
            document.querySelectorAll('[data-lang]').forEach(element => {
                if (element.getAttribute('data-lang') === lang) {
                    element.style.display = '';
                } else {
                    element.style.display = 'none';
                }
            });
            // Also update the lang attribute of the html tag for accessibility
            document.documentElement.setAttribute('lang', lang);
            localStorage.setItem('selectedLanguage', lang);
        }

        async function fetchDailySalesReport() {
            systemFeedbackParagraph.textContent = 'Fetching daily sales report...';
            updateStatusMessage(true, "Fetching daily sales report...");
            try {
                const response = await fetch(`${backendUrl}/daily_sales_report`);
                const data = await response.json();

                if (data.error) {
                    systemFeedbackParagraph.textContent = `Report Error: ${data.error}`;
                    updateStatusMessage(false, `Daily sales report failed: ${data.error}`);
                } else {
                    const reportMessage = `Today's Sales Report: Bills: ${data.total_bills}, Revenue: ₹${data.total_revenue}, Discounts: ₹${data.total_discounts}, Taxes: ₹${data.total_taxes}.`;
                    systemFeedbackParagraph.textContent = reportMessage;
                    speak(reportMessage);
                    updateStatusMessage(true, "Daily sales report fetched.");
                }
            } catch (error) {
                console.error('Error fetching daily sales report:', error);
                systemFeedbackParagraph.textContent = 'Network Error or Backend is Down for reports.';
                updateStatusMessage(false, 'Network error or backend is down for reports.');
            }
        }
    } else if (document.body.classList.contains('payment-page')) {
        document.body.classList.add('page-enter-active'); // Apply enter animation
        // No specific script logic for payment.html needed for now, as it's static.
        // Potentially add event listeners for payment confirmation or navigation back.
    }
});