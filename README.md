# LWC Image Viewer

A Salesforce Lightning Web Component for displaying images from Case records with zoom and pan capabilities. This component intelligently displays images from a parent Case (if one exists) or falls back to the current Case.

## Features

- **Smart Image Source Detection**
  - Automatically displays images from parent Case (via `ParentId` field)
  - Falls back to current Case if no parent exists
  - Dynamic card title updates based on image source
- **Image Viewer Capabilities**
  - Zoom in/out with buttons or mouse wheel (1x to 4x)
  - Pan functionality - drag to move around zoomed images
  - Navigation arrows to browse multiple images
  - Support for PNG, JPG, JPEG, and HEIC formats
- **Modern UI**
  - SLDS-compliant design
  - Responsive layout
  - Clean, professional interface

## Project Structure

```
force-app/
└── main/
    └── default/
        ├── classes/
        │   ├── ParentCaseImageController.cls
        │   ├── ParentCaseImageController.cls-meta.xml
        │   ├── ParentCaseImageControllerTest.cls
        │   └── ParentCaseImageControllerTest.cls-meta.xml
        └── lwc/
            └── parentCaseImageViewer/
                ├── parentCaseImageViewer.html
                ├── parentCaseImageViewer.js
                ├── parentCaseImageViewer.js-meta.xml
                └── parentCaseImageViewer.css
```

## Installation

### Prerequisites

- Salesforce DX CLI (`sf` or `sfdx`)
- Salesforce org with access to Case object
- Basic knowledge of Salesforce deployment

### Deployment Steps

1. **Clone this repository:**
   ```bash
   git clone https://github.com/srobbins-sfdc/LWC_ImageViewer.git
   cd LWC_ImageViewer
   ```

2. **Authenticate with your Salesforce org:**
   ```bash
   sf org login web --alias myOrg
   ```

3. **Deploy to your org:**
   ```bash
   sf project deploy start --target-org myOrg
   ```

   **Alternative:** Deploy using the manifest:
   ```bash
   sf project deploy start --manifest manifest/package.xml --target-org myOrg
   ```

### Configuration

1. Open Lightning App Builder
2. Navigate to a Case record page
3. Drag the **Parent Case Image Viewer** component onto the page
4. Save and activate the page

## Usage

### Image Source Logic

The component automatically determines which images to display:

1. **Parent Case Priority:** If the Case has a `ParentId`, images from the parent Case are displayed
2. **Fallback:** If no parent exists, images from the current Case are shown
3. **Dynamic Title:** Card title updates to reflect the source ("Parent Case Images" or "Case Images")

### Controls

- **Navigation:** Use left/right arrows to browse through multiple images
- **Zoom In:** Click the `+` button or scroll up with mouse wheel
- **Zoom Out:** Click the `-` button or scroll down with mouse wheel
- **Reset Zoom:** Click the reset button to return to 1x zoom
- **Pan:** When zoomed in, click and drag to move around the image

## Component Details

### Apex Controller: ParentCaseImageController

- **Method**: `getCaseImages(Id caseId)`
- **Returns**: ImageResult wrapper containing:
  - `images`: List of ContentVersion records with image information
  - `fromParentCase`: Boolean indicating if images are from parent or current case
- **Logic**: Checks ParentId first, falls back to current Case if no parent
- **Caching**: Enabled for improved performance
- **Test Coverage**: Included in ParentCaseImageControllerTest class

### Lightning Web Component: parentCaseImageViewer

- **Targets**: Lightning Record Page (Case object)
- **Input**: Current Case record ID
- **Display**: Responsive image viewer with navigation controls
- **Smart Source**: Automatically selects parent or current case images
- **Dynamic UI**: Card title updates based on image source

## Supported Image Formats

- PNG (.png)
- JPEG (.jpg, .jpeg)
- HEIC (.heic)

## Technical Details

- Uses standard Salesforce `ParentId` field on Case object
- Images must be attached as Files (ContentVersion records)
- Apex controller includes caching for performance
- Fully covered by unit tests

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify for your Salesforce projects.

