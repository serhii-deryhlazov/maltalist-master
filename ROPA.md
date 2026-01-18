# Record of Processing Activities (ROPA)
## MaltaListing - Article 30 GDPR Compliance

**Controller:** Serhii Deryhlazov trading as MaltaListing  
**VAT Number:** MT32290602  
**Address:** Victoria, Racecourse street, Xagħra, Gozo, Malta  
**Contact:** contact@maltalisting.com  
**Last Updated:** 18 January 2026

---

## 1. User Registration & Authentication

### Purpose of Processing
Enable user accounts for listing creation, management, and seller communication.

### Categories of Personal Data
- **Identity Data:** Full name, email address
- **Profile Data:** Google account ID, profile picture (optional), phone number (optional)
- **Authentication Data:** Google OAuth tokens (temporary session only)

### Legal Basis
- **Consent (Article 6(1)(a) GDPR)** - Users explicitly consent via checkbox before authentication
- **Contract Performance (Article 6(1)(b) GDPR)** - Necessary to provide the classified ads service

### Data Subjects
Platform users who create accounts (sellers and buyers)

### Categories of Recipients
- Google (OAuth authentication provider)
- Internal system administrators

### Data Retention Period
- **Active accounts:** Retained while account is active
- **Deleted accounts:** 7 years after deletion (Malta Companies Act - tax record retention requirement)

### Security Measures
- HTTPS/TLS encryption for all data transmission
- Google OAuth 2.0 for secure authentication
- CSRF token protection on all API requests
- Rate limiting (100 req/min global, 10 req/min authentication endpoints)
- Passwords not stored (OAuth only)
- Session tokens stored in localStorage (client-side)

---

## 2. Classified Listings Management

### Purpose of Processing
Enable users to create, publish, and manage classified advertisements.

### Categories of Personal Data
- **Listing Content:** Title, description, price, category, location
- **Images:** Up to 5 photos per listing
- **Metadata:** Creation date, update date, user ID (linked to creator)
- **Contact Information:** Phone number (optional, seller's choice to display)

### Legal Basis
- **Contract Performance (Article 6(1)(b) GDPR)** - Core service functionality
- **Legitimate Interest (Article 6(1)(f) GDPR)** - Platform operation and fraud prevention

### Data Subjects
Registered users who create listings

### Categories of Recipients
- Public (listing data visible to all site visitors)
- Internal system administrators
- MySQL database (self-hosted)

### Data Retention Period
- **Active listings:** Retained while listing is published
- **Deleted listings:** 90 days after deletion (allows for dispute resolution)
- **Sold/completed listings:** Retained indefinitely for transaction history (user can request deletion)

### Security Measures
- Input sanitization and validation
- SQL injection prevention
- XSS protection via Angular security
- Image size limits (5MB per image)
- File type validation (JPEG, PNG only)
- CORS policy restrictions

---

## 3. Seller Contact Information

### Purpose of Processing
Enable buyers to contact sellers about listings.

### Categories of Personal Data
- **Email address:** Retrieved from user profile (displayed on contact button click)
- **Phone number:** Optional, only if seller chooses to display
- **WhatsApp integration:** Optional link generation from phone number

### Legal Basis
- **Consent (Article 6(1)(a) GDPR)** - Sellers explicitly choose to show contact info per listing
- **Contract Performance (Article 6(1)(b) GDPR)** - Facilitating transactions

### Data Subjects
Sellers who opt to display contact information

### Categories of Recipients
- Buyers viewing the listing (after clicking "Contact Seller")
- WhatsApp Inc. (if WhatsApp link clicked)

### Data Retention Period
Same as listing retention period (see Section 2)

### Security Measures
- Contact info only revealed after explicit user action (button click)
- Email obfuscation in HTML source
- No automated scraping protection via rate limiting

---

## 4. Payment Processing (Stripe)

### Purpose of Processing
Process payments for listing promotions (featured ads).

### Categories of Personal Data
- **Payment Data:** Card details, billing address (processed by Stripe, not stored by MaltaListing)
- **Transaction Data:** Stripe session ID, payment intent ID, amount, date
- **Promotion Data:** Listing ID, duration (1 week, 2 weeks, or 1 month), expiration date

### Legal Basis
- **Contract Performance (Article 6(1)(b) GDPR)** - Processing payment for premium features
- **Legal Obligation (Article 6(1)(c) GDPR)** - Tax record retention (Malta Companies Act)

### Data Subjects
Users purchasing listing promotions

### Categories of Recipients
- **Stripe Inc.** (payment processor - Data Processor Agreement in place)
- Internal system administrators (transaction records only, no card details)

### Data Retention Period
- **Transaction records:** 7 years (Malta tax record retention requirement)
- **Stripe session data:** Retained by Stripe per their DPA
- **Promotion status:** Until promotion expires

### Security Measures
- **PCI DSS Level 1 compliance** via Stripe (no card data touches our servers)
- Stripe Checkout hosted payment pages
- Payment verification via Stripe API
- HTTPS for all payment-related requests
- Transaction logging with tamper protection
- **Consumer Rights Compliance:** Mandatory checkbox requiring users to acknowledge 14-day withdrawal right waiver before payment (promotion activates immediately upon purchase)

---

## 5. Server Logs & Analytics

### Purpose of Processing
Security monitoring, performance optimization, and fraud prevention.

### Categories of Personal Data
- **IP addresses:** Automatically logged by nginx
- **Request logs:** Timestamps, HTTP method, URL path, user agent
- **Error logs:** Stack traces (no personal data in error messages)
- **Docker stats:** Container metrics (no personal data)

### Legal Basis
- **Legitimate Interest (Article 6(1)(f) GDPR)** - Security, performance, fraud prevention

### Data Subjects
All site visitors (authenticated and anonymous)

### Categories of Recipients
- Internal system administrators only
- No third-party analytics (no Google Analytics, no Meta Pixel beyond basic pageview tracking)

### Data Retention Period
- **Nginx access logs:** 12 months
- **Nginx error logs:** 12 months
- **Docker monitoring stats:** Rolling 200 entries (approximately 24-48 hours)
- **Application logs:** 12 months

### Security Measures
- Log file access restricted to root user only
- Logs stored on encrypted server disk
- No sensitive data (passwords, tokens) logged
- IP addresses anonymized after 12 months

---

## 6. Cookies & Local Storage

### Purpose of Processing
Session management, user preferences, authentication state.

### Categories of Personal Data
- **localStorage:** User object (name, email, ID), language preference, GDPR consent flag
- **Session cookies:** CSRF tokens, authentication tokens
- **Third-party cookies:** Google OAuth (temporary)

### Legal Basis
- **Consent (Article 6(1)(a) GDPR)** - Cookie consent banner (managed by cookie-consent component)
- **Strictly Necessary (ePrivacy Directive exception)** - Authentication and CSRF tokens

### Data Subjects
All site visitors who accept cookies

### Categories of Recipients
- Browser (client-side storage only)
- Google (OAuth cookies)

### Data Retention Period
- **localStorage:** Until user clears browser data or logs out
- **CSRF tokens:** Session duration (until browser closed)
- **Google OAuth cookies:** Per Google's policy

### Security Measures
- HttpOnly flag on sensitive cookies
- Secure flag (HTTPS only)
- SameSite=Strict on CSRF tokens
- No sensitive data in localStorage (no passwords or payment info)

---

## 7. GDPR User Rights Implementation

### Right to Access (Article 15)
**Implementation:** "Download My Data" button in Privacy Policy page  
**Format:** JSON file with all user data (profile, listings, transactions)  
**Response Time:** Immediate (automated)

### Right to Rectification (Article 16)
**Implementation:** Users can edit profile and listings directly in UI  
**Response Time:** Immediate (self-service)

### Right to Erasure (Article 17)
**Implementation:**
- "Deactivate Account" - Soft delete (7-year retention for tax compliance)
- "Delete My Account" - Hard delete after 7 years
- Users notified of 7-year retention requirement before deletion

### Right to Data Portability (Article 20)
**Implementation:** Same as Right to Access (JSON export)

### Right to Object (Article 21)
**Implementation:** Users can opt out by deleting account or not providing optional data

---

## 8. Data Transfers

### International Transfers
- **Google OAuth:** Data transferred to USA (Google LLC) - Standard Contractual Clauses in place via Google's DPA
- **Stripe:** Data transferred to USA (Stripe Inc.) - Standard Contractual Clauses in place via Stripe's DPA
- **Hosting:** Self-hosted on VPS in EU (no third-party data transfers for hosting)

### Safeguards
- Google and Stripe provide GDPR-compliant Data Processing Agreements
- Standard Contractual Clauses (SCCs) approved by EU Commission
- Both processors are Privacy Shield certified (legacy) and maintain GDPR compliance

---

## 9. Data Breach Procedures

### Detection
- Server monitoring via Docker stats dashboard
- Nginx error log monitoring
- Manual security audits (penetration testing performed)

### Notification Timeline
- **IDPC notification:** Within 72 hours of breach discovery (if high risk)
- **User notification:** Without undue delay (if high risk to rights and freedoms)
- **Documentation:** All breaches documented in internal log

### Responsible Person
Serhii Deryhlazov (Data Controller)  
Contact: contact@maltalisting.com

---

## 10. Data Protection Officer (DPO)

**Status:** Not required  
**Reasoning:**
- Small-scale operation (sole trader)
- No systematic large-scale monitoring
- No large-scale processing of special categories of data
- Not a public authority

If business grows beyond these thresholds, a DPO will be appointed and notified to IDPC.

---

## 11. Third-Party Processors

### Google LLC (OAuth Authentication)
- **Service:** Google Sign-In API
- **Data Processed:** Email, name, profile picture, Google ID
- **DPA:** Google Cloud Data Processing Agreement
- **Location:** USA (Standard Contractual Clauses)

### Stripe Inc. (Payment Processing)
- **Service:** Stripe Checkout & Payment Intents API
- **Data Processed:** Payment card details, billing information, transaction data
- **DPA:** Stripe Data Processing Agreement
- **Location:** USA (Standard Contractual Clauses)
- **Certification:** PCI DSS Level 1

### MySQL (Database)
- **Service:** Self-hosted database
- **Data Processed:** All application data
- **DPA:** N/A (self-hosted, fully controlled)
- **Location:** Self-hosted VPS (EU-based)

---

## 12. Data Protection Impact Assessment (DPIA)

**Status:** Not required at current scale

**Threshold Monitoring:**
- If platform exceeds 10,000 monthly active users
- If systematic profiling/automated decision-making implemented
- If large-scale processing of special categories begins

Then DPIA will be conducted before expansion.

---

## 13. Technical & Organizational Measures (TOMs)

### Access Control
- SSH key authentication only (no password login)
- Root access restricted to data controller
- Database access restricted to localhost (127.0.0.1:3306)
- Monitoring dashboard IP-whitelisted (single IP only)

### Encryption
- **In Transit:** TLS 1.2/1.3 for all HTTPS connections
- **At Rest:** VPS disk encryption
- **Backups:** Encrypted SQL dumps

### Pseudonymization
- User IDs are UUIDs (Google OAuth IDs), not sequential integers
- IP addresses anonymized after retention period

### Availability & Resilience
- Automated backups every 2 hours (6 retained)
- Docker container health monitoring
- Nginx rate limiting (DDoS mitigation)

### Regular Testing
- Penetration testing performed (2025)
- Manual security audits of authentication flow
- E2E test suite for critical user flows

### Incident Response
- Error logging and monitoring in place
- Docker stats dashboard for anomaly detection
- Manual daily checks of system health

---

## 14. Changes to This ROPA

This document will be reviewed and updated:
- **Annually** (minimum)
- **When new processing activities are added**
- **After any data breach or security incident**
- **When GDPR guidance or Malta law changes**

---

## 15. Contact for Data Protection Queries

**Data Controller:** Serhii Deryhlazov  
**Email:** contact@maltalisting.com  
**Address:** Victoria, Racecourse street, Xagħra, Gozo, Malta  

**Supervisory Authority:** Information and Data Protection Commissioner (IDPC)  
**Website:** https://idpc.org.mt  
**Email:** idpc.info@idpc.org.mt  

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 12 Jan 2026 | Initial ROPA creation | Serhii Deryhlazov |
| 1.1 | 18 Jan 2026 | Added consumer rights waiver checkbox for promotions | Serhii Deryhlazov |
| 1.2 | 18 Jan 2026 | Added comprehensive prohibited content list to Terms of Service (DSA compliance) | Serhii Deryhlazov |

---

**Note:** This document is for internal use and must be made available to the IDPC upon request. It is not published on the website but referenced in the Privacy Policy.
