# Diplomas as NFTs

Overview URL: https://app.toolblox.net/summary/diplomas_as_nfts

## Overview:

The "Diplomas as NFTs" workflow in Toolblox is designed to facilitate the issuance of diplomas or certificates as non-transferrable NFTs (Non-Fungible Tokens) on the blockchain. This workflow leverages the NonTransferrableERC721, ERC721, and ERC721Enumerable standards, ensuring that the diploma, once minted, remains with the original holder and cannot be transferred to another address.

### Use Cases:

1.  **Issuance of Diplomas/Certificates**:
    
    *   Educational institutions, training organizations, or any certification body can utilize this workflow to issue diplomas or certificates to their students or participants.
    *   The diploma details, including its name, description, and an image (possibly a visual representation or scan), are stored on the blockchain.
    *   The holder's address ensures that the diploma is associated with a specific individual or entity.
2.  **Verification and Authentication**:
    
    *   Employers, institutions, or any third party can verify the authenticity of a diploma by checking its presence on the blockchain. This ensures that the diploma is genuine and has been issued by a recognized entity.
    *   The non-transferrable nature of the NFT ensures that the diploma remains with the original recipient, preventing any potential misuse or misrepresentation.
3.  **Digital Showcase**:
    
    *   Graduates or certificate holders can showcase their achievements on digital platforms, portfolios, or social media by sharing their NFT-based diplomas. This provides a modern, digital alternative to traditional paper certificates.

### Why Diplomas as a Smart Contract Makes Sense:

1.  **Immutable Record**: Once a diploma is minted as an NFT and added to the blockchain, it becomes an immutable record. This ensures that the diploma cannot be tampered with or altered, providing a high level of trust and authenticity.
    
2.  **Reduction in Forgery**: The blockchain-based nature of the diploma reduces the chances of forgery. Traditional paper-based diplomas can be replicated or falsified, but an NFT-based diploma on the blockchain provides a verifiable proof of its legitimacy.
    
3.  **Easy Verification**: For entities that need to verify the authenticity of a diploma (e.g., employers during hiring), the blockchain provides a quick and reliable method. They can easily check the diploma against the blockchain record.
    
4.  **Environmental Benefits**: Digital diplomas reduce the need for paper, ink, and other resources associated with traditional diploma issuance, contributing to environmental sustainability.
    
5.  **Global Accessibility**: NFT-based diplomas are accessible from anywhere in the world, making it easier for international students or professionals to share and verify their qualifications across borders.
    
In summary, the "Diplomas as NFTs" workflow in Toolblox offers a modern, secure, and efficient solution to the challenges associated with traditional diploma issuance and verification. It harnesses the power of blockchain technology to bring trust, transparency, and convenience to the world of academic and professional achievements.

## Properties
The object has the following properties:

* `Id` (Integer)
* `Status` (Integer)
* `Name` (String)
* `Description` (String)
* `Image` (Image)
* `Holder` (Address)

## States
The workflow includes 1 states:

* Issued

## Transitions
### <a name="tran_issue"></a>
Transition: 'Issue'
This transition creates a new object and puts it into `Issued` state.

#### Transition Parameters
For this transition, the following parameters are required: 

* `Name` (Text)
* `Description` (Text)
* `Image` (Image)
* `Holder` (User)

#### Access Restrictions
Access is exclusively limited to the owner of the workflow.

#### Checks and updates
The following properties will be updated on blockchain:

* `Name` (String)
* `Description` (String)
* `Image` (Image)
* `Holder` (Address)