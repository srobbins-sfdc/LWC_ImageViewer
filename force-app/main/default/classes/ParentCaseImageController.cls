public with sharing class ParentCaseImageController {
    
    /**
     * Wrapper class to return both images and metadata about their source
     */
    public class ImageResult {
        @AuraEnabled public List<ContentVersion> images { get; set; }
        @AuraEnabled public Boolean fromParentCase { get; set; }
        
        public ImageResult(List<ContentVersion> imgs, Boolean isFromParent) {
            this.images = imgs;
            this.fromParentCase = isFromParent;
        }
    }
    
    /**
     * Retrieves image files from a parent Case record, or from the current Case if no parent exists
     * @param caseId The ID of the current Case record
     * @return ImageResult containing images and source information
     */
    @AuraEnabled(cacheable=true)
    public static ImageResult getCaseImages(Id caseId) {
        try {
            // Query the current Case to get the ParentId field
            Case currentCase = [
                SELECT Id, ParentId 
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
            
            // Determine which Case to get images from
            Boolean hasParent = currentCase.ParentId != null;
            Id targetCaseId = hasParent ? currentCase.ParentId : currentCase.Id;
            
            // Query ContentDocumentLinks for the target Case
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :targetCaseId
            ];
            
            // If no documents are linked, return empty result
            if (docLinks.isEmpty()) {
                return new ImageResult(new List<ContentVersion>(), hasParent);
            }
            
            // Build set of ContentDocument IDs
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink cdl : docLinks) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
            
            // Query ContentVersion records for images
            List<ContentVersion> imageVersions = [
                SELECT Id, Title, FileExtension, ContentDocumentId, VersionDataUrl
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
                AND IsLatest = true
                AND FileExtension IN ('png', 'jpg', 'jpeg', 'heic')
                ORDER BY CreatedDate DESC
            ];
            
            return new ImageResult(imageVersions, hasParent);
            
        } catch (Exception e) {
            // Log the error and return empty result
            System.debug('Error in getCaseImages: ' + e.getMessage());
            return new ImageResult(new List<ContentVersion>(), false);
        }
    }
}
