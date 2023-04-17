//
//  ContentView.swift
//  RenameFilesFromFolder
//
//  Created by Galatanu Bogdan on 14.04.2023.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var input1: String = ""
    @State private var input2: String = ""
    
    @State private var numOfRenamedFiles: Int = 0
    
    enum ActionsTypes {
        case renameFilesWithPrefixAndCountItemsByTheirModificationDate
        case removePrefixFromFiles
    }
    
    var body: some View {
        VStack {
            Button(action: {
                let openPanel = NSOpenPanel()
                openPanel.canChooseFiles = false
                openPanel.canChooseDirectories = true
                openPanel.allowsMultipleSelection = false
                openPanel.prompt = "Select"
                
                if openPanel.runModal() == NSApplication.ModalResponse.OK{
                    if let selectedFileURL = openPanel.url {
                        input1 = selectedFileURL.absoluteString
                        
                        if input1.hasSuffix("/")
                        {
                            input1 = String(input1.dropLast());
                        }
                        
                        if input1.hasPrefix("file://")
                        {
                            input1 = String(input1.dropFirst(7));
                        }
                        
                        input1 = input1.replacingOccurrences(of: "%20", with: " ")
                    }
                }
            })
            {
                
                if input1.count > 0
                {
                    Text("Selected Directory: \(input1)")
                }
                else
                {
                    Text("Choose Directory")
                }
                
            }
            .padding(10)
            
            
            TextField("Prefix Name", text: $input2)
                .padding(.horizontal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .scaleEffect(0.8) // size
            
            HStack{
                Button(action: {
                    processActions(actionType: ActionsTypes.renameFilesWithPrefixAndCountItemsByTheirModificationDate)
                }) {
                    Text("RenameFiles")
                }
                .padding(10)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                .scaleEffect(0.8) // size
                
                Button(action: {
                    processActions(actionType: ActionsTypes.removePrefixFromFiles)
                }) {
                    Text("RemovePrefix")
                }
                .padding(10)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                .scaleEffect(0.8) // size
            }
            
            
        }
    }
    
    func processActions(actionType: ActionsTypes)
    {
        if !validateInput()
        {
            return;
        }
        
        numOfRenamedFiles = 0
        var files: [String] = getFilesInDirectory(input1)
        files = sortFilePathsByModificationDate(files)
        
        processFiles(prefix:input2, files:files, processAction: actionType)
        
        // Display a popup message with the number of files renamed
        let message =
        "Total num of files \(files.count).\nRenamed \(numOfRenamedFiles) files.\nCannot rename \(files.count - numOfRenamedFiles) files."
        
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
    
    //    func createFilesWithContent(count: Int, directoryPath: String) {
    //        let fileManager = FileManager.default
    //
    //        for i in 1...count {
    //            let fileName = "file\(i).txt"
    //            let filePath = directoryPath + "/" + fileName
    //
    //            if !fileManager.fileExists(atPath: filePath) {
    //                do {
    //                    try String(i).write(toFile: filePath, atomically: true, encoding: .utf8)
    //                } catch {
    //                    print("Error creating file: \(error)")
    //                }
    //            }
    //        }
    //    }
    
    func validateInput() -> Bool
    {
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: input1, isDirectory: &isDirectory)
        var errorMessage: String = "";
        if exists && isDirectory.boolValue {
            // Directory exists
        } else {
            errorMessage = errorMessage + "Directory doesn't exist. Change the directory\n";
        }
        
        if input2.count == 0
        {
            errorMessage = errorMessage + "Prefix is empty. Please add a prefix";
        }
        
        if(errorMessage.count > 0)
        {
            let alert = NSAlert()
            alert.messageText = errorMessage
            alert.runModal()
            return false
        }
        
        return true;
    }
    
    func sortFilePathsByModificationDate(_ filePaths: [String]) -> [String] {
        let fileManager = FileManager.default
        
        // Sort the file paths by their modification date
        let sortedFilePaths = filePaths.sorted { (path1, path2) -> Bool in
            do {
                let attrs1 = try fileManager.attributesOfItem(atPath: path1)
                let attrs2 = try fileManager.attributesOfItem(atPath: path2)
                if let modDate1 = attrs1[.modificationDate] as? Date,
                   let modDate2 = attrs2[.modificationDate] as? Date {
                    if(modDate1 == modDate2){
                        return path1.lowercased() < path2.lowercased()
                    }
                    else{
                        return modDate1 < modDate2}
                }
            } catch {
                print("Error getting file attributes: \(error)")
            }
            return false
        }
        return sortedFilePaths
    }
    
    func getFilesInDirectory(_ directoryPath: String) -> [String] {
        let fileManager = FileManager.default
        var files: [String] = []
        
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            for file in directoryContents {
                var isDirectory: ObjCBool = false
                let filePath = directoryPath + "/" + file
                if !file.hasPrefix(".") && fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory) && !isDirectory.boolValue {
                    files.append(filePath)
                }
            }
        } catch {
            print("Error getting files from directory: \(error)")
        }
        
        return files
    }
    
    func getFormattedCount(count: Int, numOfDigitsToDisplay: Int) -> String
    {
        var formattedCount: String = String(count)
        
        while(formattedCount.count < numOfDigitsToDisplay)
        {
            formattedCount = "0" + formattedCount
        }
        
        return formattedCount
    }
    
    func processFiles(prefix: String, files: [String], processAction: ActionsTypes) {
        var count = 1
        let numOfFilesDigitsCount:Int = String(files.count).count
        
        for file in files {
            let url = URL(fileURLWithPath: file)
            let pathExtension = url.pathExtension
            let fileName = url.lastPathComponent
            
            var newPath: URL? = nil
            
            if processAction == ActionsTypes.removePrefixFromFiles && fileName.hasPrefix(prefix)
            {
                newPath = url.deletingLastPathComponent().appendingPathComponent(String(fileName.dropFirst(prefix.count)))
            }
            else if processAction == ActionsTypes.renameFilesWithPrefixAndCountItemsByTheirModificationDate
            {
                newPath = url.deletingLastPathComponent().appendingPathComponent("\(prefix)\(getFormattedCount(count: count, numOfDigitsToDisplay: numOfFilesDigitsCount)).\(pathExtension)")
            }
            
            if(newPath != nil)
            {
                do {
                    try FileManager.default.moveItem(at: url, to: newPath!)
                    numOfRenamedFiles += 1
                } catch {
                    print("Error renaming file: \(error.localizedDescription)")
                }
                count += 1
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
