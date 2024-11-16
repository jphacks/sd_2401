import Foundation
import SwiftSoup

func getNewsContent(url: String) -> String? {
    var Content: String?
    var p_content: String?

    do {
        let sourceHTML = try String(contentsOf: URL(string: url)!, encoding: String.Encoding.utf8)
        let document: Document = try SwiftSoup.parse(sourceHTML)
        let paragraphs: Elements = try document.select("p")
        p_content = paragraphs.array().map { try? $0.text() }.compactMap { $0 }.joined(separator: "\n")
    }
    catch {
        p_content = nil
        print("Could not get HTML")
    }

    let prompt = """
    [HTML Source]
    \(p_content)

    Please extract news aritcle from [HTML Source] above.

    [Output]
    """

    let conversationManager = ConversationManager(
        apiKey:Config.openai_apiKey
    )

    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    conversationManager.Conversation(prompt: prompt) { response in
        if let res = response {
            Content = res
        } else {
            Content = nil
        }
        dispatchGroup.leave()
    }

    // 非同期処理を待つ
    dispatchGroup.wait()
    
    return Content
}

func getNewsContent(url: URL) async -> String? {
    var Content: String?
    var sourceHTML: String?
    
    do {
        sourceHTML = try String(contentsOf: url, encoding: String.Encoding.utf8)
    } catch {
        sourceHTML = nil
        print("Could not get HTML")
    }
    
    let prompt = """
    [HTML Source]
    \(sourceHTML ?? "")
    
    Please extract news article from [HTML Source] above.
    
    [Output]
    """
    
    let conversationManager = ConversationManager(
        apiKey: Config.openai_apiKey
    )
    
    return await withCheckedContinuation { continuation in
        conversationManager.Conversation(prompt: prompt) { response in
            if let res = response {
                Content = res
            } else {
                Content = nil
            }
            continuation.resume(returning: Content)
        }
    }
}
