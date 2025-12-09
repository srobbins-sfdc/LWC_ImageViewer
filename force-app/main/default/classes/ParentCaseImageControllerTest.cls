@isTest
private class ParentCaseImageControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create parent Case
        Case parentCase = new Case(
            Subject = 'Parent Case',
            Status = 'New',
            Origin = 'Web'
        );
        insert parentCase;
        
        // Create child Case
        Case childCase = new Case(
            Subject = 'Child Case',
            Status = 'New',
            Origin = 'Web',
            ParentId = parentCase.Id
        );
        insert childCase;
        
        // Create a ContentVersion (file)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Image',
            PathOnClient = 'testimage.png',
            VersionData = Blob.valueOf('Test image content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get the ContentDocumentId
        ContentVersion insertedCV = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id 
            LIMIT 1
        ];
        
        // Link the file to the parent Case
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = parentCase.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    @isTest
    static void testGetCaseImagesWithParentCase() {
        // Get the child Case
        Case childCase = [
            SELECT Id 
            FROM Case 
            WHERE Subject = 'Child Case' 
            LIMIT 1
        ];
        
        // Test the method
        Test.startTest();
        ParentCaseImageController.ImageResult result = ParentCaseImageController.getCaseImages(childCase.Id);
        Test.stopTest();
        
        // Assert that images were returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.images, 'Images list should not be null');
        System.assertEquals(true, result.fromParentCase, 'Should indicate images are from parent case');
        System.assertEquals(1, result.images.size(), 'Should return 1 image');
        System.assertEquals('png', result.images[0].FileExtension, 'File extension should be png');
        System.assertEquals('Test Image', result.images[0].Title, 'Image title should match');
    }
    
    @isTest
    static void testGetCaseImagesWithoutParentCase() {
        // Create a standalone Case without parent
        Case standaloneCase = new Case(
            Subject = 'Standalone Case',
            Status = 'New',
            Origin = 'Web'
        );
        insert standaloneCase;
        
        // Create and attach an image to the standalone Case
        ContentVersion cv = new ContentVersion(
            Title = 'Standalone Image',
            PathOnClient = 'standalone.jpg',
            VersionData = Blob.valueOf('Standalone image content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get the ContentDocumentId
        ContentVersion insertedCV = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id 
            LIMIT 1
        ];
        
        // Link the file to the standalone Case
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = standaloneCase.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Test the method
        Test.startTest();
        ParentCaseImageController.ImageResult result = ParentCaseImageController.getCaseImages(standaloneCase.Id);
        Test.stopTest();
        
        // Assert that images from the current Case are returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.images, 'Images list should not be null');
        System.assertEquals(false, result.fromParentCase, 'Should indicate images are from current case');
        System.assertEquals(1, result.images.size(), 'Should return 1 image from the current Case');
        System.assertEquals('Standalone Image', result.images[0].Title, 'Image title should match');
    }
    
    @isTest
    static void testGetCaseImagesWithNoFiles() {
        // Create parent Case without files
        Case parentCase = new Case(
            Subject = 'Parent Case No Files',
            Status = 'New',
            Origin = 'Web'
        );
        insert parentCase;
        
        // Create child Case
        Case childCase = new Case(
            Subject = 'Child Case No Files',
            Status = 'New',
            Origin = 'Web',
            ParentId = parentCase.Id
        );
        insert childCase;
        
        // Test the method
        Test.startTest();
        ParentCaseImageController.ImageResult result = ParentCaseImageController.getCaseImages(childCase.Id);
        Test.stopTest();
        
        // Assert that no images were returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.images, 'Images list should not be null');
        System.assertEquals(true, result.fromParentCase, 'Should indicate checking parent case');
        System.assertEquals(0, result.images.size(), 'Should return 0 images when parent Case has no files');
    }
    
    @isTest
    static void testGetCaseImagesMultipleFormats() {
        // Get parent Case
        Case parentCase = [
            SELECT Id 
            FROM Case 
            WHERE Subject = 'Parent Case' 
            LIMIT 1
        ];
        
        // Create additional image files with different formats
        List<ContentVersion> cvList = new List<ContentVersion>();
        
        cvList.add(new ContentVersion(
            Title = 'JPEG Image',
            PathOnClient = 'testimage.jpg',
            VersionData = Blob.valueOf('JPEG content'),
            IsMajorVersion = true
        ));
        
        cvList.add(new ContentVersion(
            Title = 'HEIC Image',
            PathOnClient = 'testimage.heic',
            VersionData = Blob.valueOf('HEIC content'),
            IsMajorVersion = true
        ));
        
        // Insert a non-image file (should be filtered out)
        cvList.add(new ContentVersion(
            Title = 'PDF Document',
            PathOnClient = 'testdoc.pdf',
            VersionData = Blob.valueOf('PDF content'),
            IsMajorVersion = true
        ));
        
        insert cvList;
        
        // Get ContentDocumentIds
        List<ContentVersion> insertedCVs = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :cvList
        ];
        
        // Link all files to parent Case
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedCVs) {
            cdlList.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = parentCase.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert cdlList;
        
        // Get child Case
        Case childCase = [
            SELECT Id 
            FROM Case 
            WHERE Subject = 'Child Case' 
            LIMIT 1
        ];
        
        // Test the method
        Test.startTest();
        ParentCaseImageController.ImageResult result = ParentCaseImageController.getCaseImages(childCase.Id);
        Test.stopTest();
        
        // Assert results (1 from setup + 2 new images, PDF should be filtered out)
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.images, 'Images list should not be null');
        System.assertEquals(true, result.fromParentCase, 'Should indicate images are from parent case');
        System.assertEquals(3, result.images.size(), 'Should return 3 images (PNG, JPG, HEIC), PDF filtered out');
        
        // Verify all returned files are images
        Set<String> validExtensions = new Set<String>{'png', 'jpg', 'jpeg', 'heic'};
        for (ContentVersion cv : result.images) {
            System.assert(validExtensions.contains(cv.FileExtension.toLowerCase()), 
                'All returned files should have valid image extensions');
        }
    }
}

