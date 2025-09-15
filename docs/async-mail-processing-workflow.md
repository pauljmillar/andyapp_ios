# Asynchronous Mail Processing Workflow

## Overview

This document outlines the asynchronous mail processing workflow for the AndyApp iOS application. The goal is to allow users to scan multiple mail packages without waiting for AI processing and survey completion, creating a better user experience.

## Current vs. Target Workflow

### Current Workflow (Synchronous)
1. User scans images → OCR → Upload → AI Processing → Survey → Complete
2. User must wait for each step to complete before scanning more mail
3. Only one mail package can be processed at a time

### Target Workflow (Asynchronous)
1. **Synchronous Phase**: User scans images → OCR → Upload → Return control
2. **Background Phase**: AI Processing (happens without user focus)
3. **User-Initiated Phase**: Survey completion (when user is ready)

## Detailed Workflow Steps

### Phase 1: Synchronous Scanning (Steps 1-4)
**User Experience**: Immediate feedback, can scan multiple packages

1. **Snap Image**
   - User opens camera/document scanner
   - Captures one or more images
   - Images stored locally

2. **OCR Processing**
   - Each image processed with OCR
   - Text extracted and stored locally
   - OCR text combined for processing

3. **Upload to Server**
   - Images uploaded to S3 via API
   - OCR text uploaded as document
   - Mail package record created in database

4. **Return Control to User**
   - Mail card appears in list with "Processing..." status
   - User can immediately scan more mail packages
   - Background processing queued

### Phase 2: Background Processing (Steps 5-7)
**User Experience**: No interaction required, happens automatically

5. **AI Processing**
   - Combined OCR text sent to AI processing API
   - AI analyzes text for company, industry, offers
   - Results stored in database

6. **Update Mail Package**
   - Mail package updated with AI results
   - Industry, brand name, primary offer populated
   - Status changed to "Ready for Survey"

7. **UI Update**
   - Mail card shows "Ready for Survey" status
   - "Confirm Details" button becomes available
   - User can initiate survey when ready

### Phase 3: User-Initiated Survey (Steps 8-10)
**User Experience**: User controls when to complete survey

8. **Survey Questions**
   - User taps "Confirm Details" button
   - Survey questions presented
   - User answers questions about mail package

9. **Survey Completion**
   - Survey results sent to API
   - Mail package updated with survey data
   - Status changed to "Completed"

10. **Final Update**
    - Mail card shows checkmark
    - "Confirm Details" button disabled
    - Package marked as fully processed

## API Endpoints and Parameters

### 1. Upload Mail Scan
**Endpoint**: `POST /api/panelist/mail-scans`
**Purpose**: Upload images and OCR text to S3, create mail package

**Request Body**:
```json
{
  "mail_package_id": "string|null", // null for new package
  "document_type": "scan|ocr_text",
  "image_sequence": "number|null", // null for OCR text
  "file_data": "base64_string",
  "filename": "string",
  "mime_type": "image/jpeg|text/plain",
  "metadata": {
    "timestamp": "string",
    "sequence": "string",
    "type": "combined_ocr",
    "image_count": "string"
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "string",
  "upload_type": "scan|ocr_text",
  "scan": {
    "mailpack_id": "string",
    "s3_key": "string"
  }
}
```

### 2. Process Mail Package
**Endpoint**: `POST /api/panelist/mail-packages/{mailPackageId}/process`
**Purpose**: AI processing of combined OCR text

**Request Body**:
```json
{
  "input_text": "string", // Combined OCR text
  "processing_notes": "string"
}
```

**Response**:
```json
{
  "success": true,
  "processing_result": {
    "industry": "string",
    "brand_name": "string",
    "primary_offer": "string",
    "response_intention": "string",
    "name_check": "string",
    "urgency_level": "string",
    "estimated_value": "string"
  }
}
```

### 3. Update Mail Package
**Endpoint**: `PATCH /api/panelist/mail-packages/{mailPackageId}`
**Purpose**: Update mail package with survey results

**Request Body**:
```json
{
  "brand_name": "string",
  "industry": "string",
  "company_validated": true,
  "response_intention": "string",
  "name_check": "string",
  "notes": "string",
  "status": "completed",
  "is_approved": true,
  "processing_notes": "string"
}
```

**Response**:
```json
{
  "success": true,
  "mail_package": {
    "id": "string",
    "panelist_id": "string",
    "package_name": "string",
    "industry": "string",
    "brand_name": "string",
    "status": "completed",
    "processing_status": "completed",
    "points_awarded": 0,
    "is_approved": true,
    "created_at": "string",
    "updated_at": "string"
  }
}
```

## Mail Package States

### State Definitions
```swift
enum MailPackageState {
    case scanning        // Steps 1-4 (user can scan more)
    case processing      // Steps 5-7 (background)
    case readyForSurvey  // Steps 5-7 complete, waiting for user
    case surveyComplete  // Steps 8-10 complete
}
```

### State Transitions
1. **scanning** → **processing**: After image upload completes
2. **processing** → **readyForSurvey**: After AI processing completes
3. **readyForSurvey** → **surveyComplete**: After survey completion

## UI Components and States

### Mail Card Display
- **scanning**: "Processing..." spinner
- **processing**: "Processing..." spinner
- **readyForSurvey**: "Ready for Survey" + "Confirm Details" button
- **surveyComplete**: Checkmark + disabled button

### Mail Package Detail View
- **scanning/processing**: Show basic info, no action buttons
- **readyForSurvey**: Show "Confirm Details" button
- **surveyComplete**: Show completed status, disabled button

## Implementation Status

### ✅ Completed
- [x] Workflow documentation
- [x] API endpoint documentation
- [x] State definitions
- [x] Background processing service
- [x] Queue management
- [x] MailPackage model updates with async state tracking
- [x] Survey workflow separation
- [x] OCR data storage for background processing
- [x] Async workflow integration
- [x] UI state indicators on mail cards
- [x] "Confirm Details" button in MailPackageDetailView
- [x] Processing state visual indicators
- [x] Dynamic text content based on processing state

### 🚧 In Progress
- [ ] Error handling and retry logic

### 📋 Pending
- [ ] Advanced error recovery
- [ ] Performance optimizations
- [ ] Analytics and monitoring

## Error Handling

### Background Processing Errors
- Network failures during AI processing
- API timeouts
- Invalid OCR text
- Retry logic for failed processing

### User Experience During Errors
- Show error state on mail card
- Allow retry of failed processing
- Maintain queue order
- Preserve user's scanned images

## Testing Scenarios

### Basic Flow
1. Scan 3 images for Mail Package 1
2. Immediately scan 2 images for Mail Package 2
3. Verify both packages show "Processing..."
4. Wait for Package 1 to show "Ready for Survey"
5. Complete survey for Package 1
6. Wait for Package 2 to show "Ready for Survey"
7. Complete survey for Package 2

### Edge Cases
- Network interruption during background processing
- User closes app during processing
- Multiple rapid scans
- Survey completion failure

## Android App Coordination

This workflow should be implemented identically in the Android app with the same:
- API endpoints and parameters
- State definitions
- UI behavior
- Error handling

The Android app should use the same backend APIs and maintain consistency with the iOS implementation.
