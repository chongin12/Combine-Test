//
//  ContentView.swift
//  CombineTest
//
//  Created by 정종인 on 6/8/24.
//

import SwiftUI
import Combine

@Observable
class Noti {
    var text1: String = "이 아이는 마지막으로 버튼을 클릭한 후 0.3초가 지나야 갱신됩니다"
    var text2: String = "이 아이는 0.3초마다 최근 값으로 설정됩니다."
    var attempt: Int = 0
    var wowMoment: Bool = false
    var cancellables: Set<AnyCancellable> = []
    var attemptCancellable: AnyCancellable?

    init() {
        let textPublisher = NotificationCenter.default.publisher(for: .noti)
            .map { noti in
                noti.userInfo?["text"] as? String ?? "Unknown"
            }

        let debouncePublisher = textPublisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)

        let throttlePublisher = textPublisher
            .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: false)

        debouncePublisher
            .sink { [weak self] text in
                self?.text1 = text
            }
            .store(in: &cancellables)

        throttlePublisher
            .sink { [weak self] text in
                self?.text2 = text
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(debouncePublisher, throttlePublisher)
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .map { $0 != $1 }
            .sink { [weak self] isNotSame in
                self?.wowMoment = isNotSame

                if isNotSame {
                    self?.attemptCancellable?.cancel()
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(debouncePublisher, throttlePublisher)
            .sink { [weak self] _, _ in
                self?.wowMoment = false
            }
            .store(in: &cancellables)

        attemptCancellable = textPublisher
            .sink { _ in
                self.attempt += 1
            }
    }
}

extension Notification.Name {
    static let noti = Notification.Name("noti")
}

struct ContentView: View {
    @State var noti = Noti()

    var body: some View {
        VStack(spacing: 16) {
            Text(noti.text1)
                .font(.title)
            Text(noti.text2)
                .font(.title)
            if noti.wowMoment {
                Text("😇 Wow!!! 😇")
                    .font(.largeTitle)
            }
            Button("button") {
                NotificationCenter.default.post(name: .noti, object: nil, userInfo: ["text": "\(Int.random(in: 0..<100))"])
            }
            .buttonStyle(.borderedProminent)
            .font(.largeTitle)

            Text("최초 시도 횟수 : \(noti.attempt)")
        }
    }
}

#Preview {
    ContentView()
}
