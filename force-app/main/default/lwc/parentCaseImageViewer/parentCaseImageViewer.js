import { LightningElement, api, wire } from 'lwc';
import getCaseImages from '@salesforce/apex/ParentCaseImageController.getCaseImages';

export default class ParentCaseImageViewer extends LightningElement {
    @api recordId; // Current Case record ID
    
    images = [];
    currentImageIndex = 0;
    errorMessage = '';
    isLoading = true;
    hasParentCase = false; // Track if images are from parent or current case
    
    // Zoom and pan properties
    zoomLevel = 1;
    minZoom = 1;
    maxZoom = 4;
    zoomStep = 0.25;
    panX = 0;
    panY = 0;
    isDragging = false;
    dragStartX = 0;
    dragStartY = 0;
    
    /**
     * Wire adapter to fetch images from the Apex controller
     */
    @wire(getCaseImages, { caseId: '$recordId' })
    wiredImages({ error, data }) {
        this.isLoading = false;
        
        if (data) {
            this.images = data.images || [];
            this.hasParentCase = data.fromParentCase || false;
            this.errorMessage = '';
            
            // Reset to first image when data is loaded
            if (this.images.length > 0) {
                this.currentImageIndex = 0;
                this.resetZoomAndPan();
            }
        } else if (error) {
            this.errorMessage = 'Error loading images. Please refresh the page.';
            this.images = [];
            this.hasParentCase = false;
            console.error('Error loading images:', error);
        }
    }
    
    /**
     * Get the card title based on image source
     */
    get cardTitle() {
        if (this.hasParentCase) {
            return 'Parent Case Images';
        }
        return 'Case Images';
    }
    
    /**
     * Get the appropriate no images message
     */
    get noImagesMessage() {
        if (this.hasParentCase) {
            return 'No images found on the parent case.';
        }
        return 'No images found on this case.';
    }
    
    /**
     * Get the URL of the current image
     */
    get currentImageUrl() {
        if (this.images.length > 0 && this.currentImageIndex < this.images.length) {
            const image = this.images[this.currentImageIndex];
            
            // For HEIC files or other formats, use the VersionDataUrl
            // Note: HEIC may not display in all browsers
            if (image.VersionDataUrl) {
                return image.VersionDataUrl;
            }
            
            // Fallback to constructing URL from ContentDocumentId
            return `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${image.Id}`;
        }
        return '';
    }
    
    /**
     * Get the title of the current image
     */
    get currentImageTitle() {
        if (this.images.length > 0 && this.currentImageIndex < this.images.length) {
            const image = this.images[this.currentImageIndex];
            return `${image.Title}.${image.FileExtension}`;
        }
        return '';
    }
    
    /**
     * Get the image counter text (e.g., "1 of 3")
     */
    get imageCounter() {
        if (this.images.length > 0) {
            return `Image ${this.currentImageIndex + 1} of ${this.images.length}`;
        }
        return '';
    }
    
    /**
     * Get the zoom percentage display
     */
    get zoomPercentage() {
        return `${Math.round(this.zoomLevel * 100)}%`;
    }
    
    /**
     * Check if at maximum zoom
     */
    get isMaxZoom() {
        return this.zoomLevel >= this.maxZoom;
    }
    
    /**
     * Check if at minimum zoom
     */
    get isMinZoom() {
        return this.zoomLevel <= this.minZoom;
    }
    
    /**
     * Get the dynamic image style for zoom and pan
     */
    get imageStyle() {
        const cursorStyle = this.zoomLevel > 1 ? 'cursor: grab;' : '';
        return `transform: scale(${this.zoomLevel}) translate(${this.panX}px, ${this.panY}px); ${cursorStyle}`;
    }
    
    /**
     * Check if there are any images to display
     */
    get hasImages() {
        return !this.isLoading && this.images.length > 0 && !this.errorMessage;
    }
    
    /**
     * Check if we should show the "no images" message
     */
    get showNoImagesMessage() {
        return !this.isLoading && this.images.length === 0 && !this.errorMessage;
    }
    
    /**
     * Check if current image is the first one
     */
    get isFirstImage() {
        return this.currentImageIndex === 0;
    }
    
    /**
     * Check if current image is the last one
     */
    get isLastImage() {
        return this.currentImageIndex === this.images.length - 1;
    }
    
    /**
     * Handle clicking the Previous button
     */
    handlePrevious() {
        if (this.currentImageIndex > 0) {
            this.currentImageIndex--;
            this.resetZoomAndPan();
        }
    }
    
    /**
     * Handle clicking the Next button
     */
    handleNext() {
        if (this.currentImageIndex < this.images.length - 1) {
            this.currentImageIndex++;
            this.resetZoomAndPan();
        }
    }
    
    /**
     * Handle image loading errors
     */
    handleImageError(event) {
        console.error('Error loading image:', event);
        this.errorMessage = 'Unable to display this image. It may be in an unsupported format.';
    }
    
    /**
     * Reset zoom and pan to default
     */
    resetZoomAndPan() {
        this.zoomLevel = 1;
        this.panX = 0;
        this.panY = 0;
    }
    
    /**
     * Handle zoom in
     */
    handleZoomIn() {
        if (this.zoomLevel < this.maxZoom) {
            this.zoomLevel = Math.min(this.zoomLevel + this.zoomStep, this.maxZoom);
        }
    }
    
    /**
     * Handle zoom out
     */
    handleZoomOut() {
        if (this.zoomLevel > this.minZoom) {
            this.zoomLevel = Math.max(this.zoomLevel - this.zoomStep, this.minZoom);
            // Reset pan if zoomed out to minimum
            if (this.zoomLevel === this.minZoom) {
                this.panX = 0;
                this.panY = 0;
            }
        }
    }
    
    /**
     * Handle reset zoom
     */
    handleResetZoom() {
        this.resetZoomAndPan();
    }
    
    /**
     * Handle mouse wheel for zoom
     */
    handleWheel(event) {
        event.preventDefault();
        
        if (event.deltaY < 0) {
            // Scroll up - zoom in
            this.handleZoomIn();
        } else {
            // Scroll down - zoom out
            this.handleZoomOut();
        }
    }
    
    /**
     * Handle mouse down for panning
     */
    handleMouseDown(event) {
        if (this.zoomLevel > 1) {
            this.isDragging = true;
            this.dragStartX = event.clientX - this.panX;
            this.dragStartY = event.clientY - this.panY;
            
            // Change cursor to grabbing
            const viewport = this.template.querySelector('.image-viewport');
            if (viewport) {
                viewport.style.cursor = 'grabbing';
            }
        }
    }
    
    /**
     * Handle mouse up for panning
     */
    handleMouseUp() {
        this.isDragging = false;
        
        // Reset cursor
        const viewport = this.template.querySelector('.image-viewport');
        if (viewport) {
            viewport.style.cursor = this.zoomLevel > 1 ? 'grab' : 'default';
        }
    }
    
    /**
     * Handle mouse leave
     */
    handleMouseLeave() {
        if (this.isDragging) {
            this.handleMouseUp();
        }
    }
    
    /**
     * Handle mouse move for panning
     */
    handleMouseMove(event) {
        if (this.isDragging && this.zoomLevel > 1) {
            event.preventDefault();
            
            // Calculate new pan position
            const newPanX = event.clientX - this.dragStartX;
            const newPanY = event.clientY - this.dragStartY;
            
            // Apply pan with limits to prevent dragging too far
            const maxPan = 100 * this.zoomLevel;
            this.panX = Math.max(-maxPan, Math.min(maxPan, newPanX));
            this.panY = Math.max(-maxPan, Math.min(maxPan, newPanY));
        }
    }
}

