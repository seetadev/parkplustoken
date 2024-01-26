
# Smart contract audit management workflow

Location: https://app.toolblox.net/summary/smart_contract_auditing_8c58d275

## Overview:

This smart contract is designed to manage the auditing process of ERC721 tokens with ReentrancyGuard protection. The contract also involves the use of DERC20 currency. The workflow is structured around the stages of preparing, ordering, progressing, and completing an audit.

## Use Cases:

1.  **Service Account Role**
    
    *   **Can**: Prepare an audit
        *   **So that**: The necessary details like Name, Order, Price, Auditor, Image, and Client are set up for the audit.
        *   **Conditions**: Only when the audit is in the 'Prepared' state and access is restricted to the service account.
2.  **Client Role**
    
    *   **Can**: Pay for the audit
        *   **So that**: The audit can move from the 'Prepared' state to the 'Ordered' state.
        *   **Conditions**: Only when the audit is in the 'Prepared' state and access is restricted to the client.
3.  **Auditor Role**
    
    *   **Can**: Start the audit
        *   **So that**: The audit can move from the 'Ordered' state to the 'In progress' state.
        *   **Conditions**: Only when the audit is in the 'Ordered' state and access is restricted to the auditor.
    *   **Can**: Update the progress of the audit
        *   **So that**: Necessary updates like Name and Description can be made while the audit is ongoing.
        *   **Conditions**: Only when the audit is in the 'In progress' state and access is restricted to the auditor.
    *   **Can**: Complete the audit
        *   **So that**: Final details like Name, Image, Description, and Report can be provided, marking the audit as completed.
        *   **Conditions**: Only when the audit is in the 'In progress' state and access is restricted to the auditor.

## Why it makes sense to have this as a smart contract:

1.  **Transparency**: Every step in the auditing process is recorded on the blockchain, ensuring transparency for all parties involved.
    
2.  **Security**: The use of restricted access ensures that only authorized parties can perform specific actions, reducing the risk of unauthorized changes or malicious activities.
    
3.  **Automation**: The smart contract automates the workflow, ensuring that each step is followed in sequence and conditions are met before progressing.
    
4.  **Immutability**: Once data is recorded on the blockchain, it cannot be altered, ensuring the integrity of the audit records.
    
5.  **Trust**: With the entire process being transparent and immutable, it builds trust among the parties involved, knowing that the process is fair and tamper-proof.
    
6.  **Efficiency**: Transactions and updates are processed in real-time, reducing delays and ensuring timely completion of audits.

Available statuses:
0 Prepared (owner Service account)
1 Ordered (owner Auditor)
2 In progress (owner Auditor)
3 Completed (owner Client)

## Transition: 'Prepare audit'
This transition creates a new object and puts it into `Prepared` state.

### Transition Parameters
For this transition, the following parameters are required: 

* `Name` (Text)
* `Order` (Text)
* `Price` (Money)
* `Auditor` (Restricted user)
* `Image` (Image)
* `Client` (User)

### Access Restrictions
Access is specifically restricted to the user with the address from the `Service account` property. If `Service account` property is not yet set (and if address is a pre-registered Service account) then the method caller becomes the objects `Service account`.

### Checks and updates
The following properties will be updated on blockchain:

* `Name` (String)
* `Order` (String)
* `Price` (Money)
* `Auditor` (RestrictedAddress)
* `Image` (Image)
* `Client` (Address)

## Transition: 'Pay for audit'
This transition begins from `Prepared` and leads to the state `Ordered`.

### Access Restrictions
Access is specifically restricted to the user with the address from the `Client` property. If `Client` property is not yet set then the method caller becomes the objects `Client`.

## Transition: 'Update progress'
This transition begins from `In progress` and leads to the state `In progress`.

### Transition Parameters
For this transition, the following parameters are required: 

* `Id` (Integer) - Audit identifier
* `Name` (Text)
* `Description` (Text)

### Access Restrictions
Access is specifically restricted to the user with the address from the `Auditor` property. If `Auditor` property is not yet set (and if address is a pre-registered Auditor) then the method caller becomes the objects `Auditor`.

### Checks and updates
The following properties will be updated on blockchain:

* `Name` (String)
* `Description` (String)

## Transition: 'Complete'
This transition begins from `In progress` and leads to the state `Completed`.

### Transition Parameters
For this transition, the following parameters are required: 

* `Id` (Integer) - Audit identifier
* `Name` (Text)
* `Image` (Image)
* `Description` (Text)
* `Report` (Blob)

### Access Restrictions
Access is specifically restricted to the user with the address from the `Auditor` property. If `Auditor` property is not yet set (and if address is a pre-registered Auditor) then the method caller becomes the objects `Auditor`.

### Checks and updates
The following properties will be updated on blockchain:

* `Name` (String)
* `Image` (Image)
* `Description` (String)
* `Report` (Blob)

## Transition: 'Start'
This transition begins from `Ordered` and leads to the state `In progress`.

### Transition Parameters
For this transition, the following parameters are required: 

* `Id` (Integer) - Audit identifier
* `Description` (Text)

### Access Restrictions
Access is specifically restricted to the user with the address from the `Auditor` property. If `Auditor` property is not yet set (and if address is a pre-registered Auditor) then the method caller becomes the objects `Auditor`.

### Checks and updates
The following properties will be updated on blockchain:

* `Description` (String)