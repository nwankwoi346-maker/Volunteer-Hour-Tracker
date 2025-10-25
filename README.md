# 📊 Volunteer Hour Tracker

A comprehensive Clarity smart contract for tracking volunteer hours on the Stacks blockchain. This contract enables organizations to manage volunteer activities, verify hours worked, and reward volunteers for their contributions.

## 🚀 Features

- **👤 Volunteer Registration**: Register volunteers with name and email
- **⏰ Hour Logging**: Log volunteer hours with organization and activity details
- **✅ Hour Verification**: Verify logged hours through authorized verifiers
- **🏆 Reward System**: Earn rewards based on verified volunteer hours
- **📈 Activity Tracking**: Comprehensive tracking of all volunteer sessions
- **🔐 Access Control**: Owner-controlled verifier management

## 📋 Contract Functions

### Public Functions

#### `register-volunteer(name, email)`
Register a new volunteer in the system.
- **Parameters**: 
  - `name`: (string-ascii 50) - Volunteer's name
  - `email`: (string-ascii 100) - Volunteer's email address
- **Returns**: Volunteer ID

#### `log-hours(organization, activity, hours)`
Log volunteer hours for a specific activity.
- **Parameters**:
  - `organization`: (string-ascii 100) - Organization name
  - `activity`: (string-ascii 200) - Activity description
  - `hours`: uint - Number of hours (1-24)
- **Returns**: Session ID

#### `verify-session(session-id)`
Verify a volunteer session (owner or authorized verifier only).
- **Parameters**: 
  - `session-id`: uint - ID of the session to verify
- **Returns**: Success confirmation

#### `claim-rewards(amount)`
Claim earned rewards from verified hours.
- **Parameters**: 
  - `amount`: uint - Amount of rewards to claim
- **Returns**: Amount claimed

#### `register-organization-verifier(organization)`
Register as a verifier for an organization (owner only).
- **Parameters**: 
  - `organization`: (string-ascii 100) - Organization name
- **Returns**: Success confirmation

#### `update-reward-rate(new-rate)`
Update the reward rate per hour (owner only).
- **Parameters**: 
  - `new-rate`: uint - New reward rate
- **Returns**: Success confirmation

#### `deactivate-volunteer(volunteer-id)`
Deactivate a volunteer account (owner or volunteer only).
- **Parameters**: 
  - `volunteer-id`: uint - ID of volunteer to deactivate
- **Returns**: Success confirmation

### Read-Only Functions

#### `get-volunteer-info(volunteer-id)`
Get detailed information about a volunteer.
- **Returns**: Volunteer data or none

#### `get-volunteer-by-principal(principal-addr)`
Get volunteer information by their principal address.
- **Returns**: Volunteer data or none

#### `get-session-info(session-id)`
Get detailed information about a volunteer session.
- **Returns**: Session data or none

#### `get-volunteer-session(volunteer-id, session-index)`
Get a specific session for a volunteer by index.
- **Returns**: Session data or none

#### `get-volunteer-session-count(volunteer-id)`
Get the total number of sessions for a volunteer.
- **Returns**: Session count

#### `get-total-hours()`
Get the total hours tracked across all volunteers.
- **Returns**: Total hours

#### `get-reward-rate()`
Get the current reward rate per hour.
- **Returns**: Reward rate

#### `get-contract-stats()`
Get overall contract statistics.
- **Returns**: Contract statistics object

#### `is-organization-verifier(organization, principal-addr)`
Check if an address is a verifier for an organization.
- **Returns**: True/false

## 🎯 Usage Examples

### 1. Register as a Volunteer
```clarity
(contract-call? .volunteer-hour-tracker register-volunteer "John Doe" "john@example.com")
```

### 2. Log Volunteer Hours
```clarity
(contract-call? .volunteer-hour-tracker log-hours "Food Bank" "Meal Preparation" u4)
```

### 3. Verify Hours (as verifier)
```clarity
(contract-call? .volunteer-hour-tracker verify-session u1)
```

### 4. Claim Rewards
```clarity
(contract-call? .volunteer-hour-tracker claim-rewards u40)
```

## 🔧 Error Codes

- `u100`: Owner-only function
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Invalid hours (must be 1-24)
- `u104`: Session not verified
- `u105`: Session already verified
- `u106`: Insufficient reward balance

## 📊 Data Structure

### Volunteer Record
```clarity
{
  principal: principal,
  name: (string-ascii 50),
  email: (string-ascii 100),
  total-hours: uint,
  verified-hours: uint,
  reward-balance: uint,
  registration-block: uint,
  active: bool
}
```

### Session Record
```clarity
{
  volunteer-id: uint,
  organization: (string-ascii 100),
  activity: (string-ascii 200),
  hours: uint,
  start-block: uint,
  end-block: uint,
  verified: bool,
  verifier: (optional principal),
  verification-block: (optional uint)
}
```

## 🛠️ Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed

### Testing
```bash
clarinet check
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🎉 Acknowledgments

- Built with [Clarity](https://clarity-lang.org/) smart contract language
- Deployed on [Stacks](https://www.stacks.co/) blockchain
- Developed with [Clarinet](https://github.com/hirosystems/clarinet) toolkit

---

**Happy Volunteering! 🌟**
