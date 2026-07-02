function mergeAllDocsInFolder() {
  // 1. Replace with the ID of the folder containing your notes
  var folderId = 'YOUR_FOLDER_ID_HERE'; 
  
  // 2. Creates the new master document in the root of your Drive
  var masterDoc = DocumentApp.create('MASTER_HDV_NOTES_DUMP');
  var masterBody = masterDoc.getBody();
  
  var folder = DriveApp.getFolderById(folderId);
  var files = folder.getFilesByType(MimeType.GOOGLE_DOCS);
  
  masterBody.appendParagraph('=== MASTER SYSTEM DUMP ===\n\n');
  
  var count = 0;
  while (files.hasNext()) {
    var file = files.next();
    try {
      var doc = DocumentApp.openById(file.getId());
      var text = doc.getBody().getText();
      
      // Append a clear header for each document
      masterBody.appendParagraph('--- BEGIN DOCUMENT: ' + file.getName() + ' ---');
      masterBody.appendParagraph(text);
      masterBody.appendParagraph('\n--- END DOCUMENT: ' + file.getName() + ' ---\n\n');
      
      count++;
    } catch (e) {
      masterBody.appendParagraph('Error reading file: ' + file.getName() + ' - ' + e.message);
    }
  }
  
  Logger.log('Successfully merged ' + count + ' documents into: MASTER_HDV_NOTES_DUMP');
}