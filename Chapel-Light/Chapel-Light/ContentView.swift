//
//  ContentView.swift
//  Chapel-Light
//
//  Created by つだ かなた   on 2026/05/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var controller = LightingController()
    @AppStorage("hasShownAboutOnFirstLaunch") private var hasShownAboutOnFirstLaunch = false
    @State private var showAbout = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // ヘッダー
                ZStack {
                    Text("同志社高等学校 チャペル舞台照明シミュレーター")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    HStack {
                        Button(action: { showResetConfirmation = true }) {
                            Text("リセット")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .foregroundColor(.red)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        Button(action: { showAbout = true }) {
                            Text("アプリについて")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, safeAreaTop(geometry: geometry) + 8) // SafeAreaを考慮しつつ背景は上まで伸ばす
                .padding(.bottom, 8)
                .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.top))
                .border(Color.gray.opacity(0.3), width: 1)
                
                // プレビューエリア
                LightPreviewView(controller: controller)
                    .frame(height: geometry.size.height * 0.35) // 35%を使用（フッター削除分広げる）
                    .border(Color.gray.opacity(0.5), width: 1)
                
                // フェーダーエリア
                HStack(spacing: 0) {
                    // A/B 系統フェーダーバンク
                    VStack(spacing: 0) {
                        FaderBankView(controller: controller, bankType: "B")
                        Divider().background(Color.gray)
                        FaderBankView(controller: controller, bankType: "A")
                    }
                    
                    Divider().background(Color.gray)
                    
                    // クロスフェーダー
                    CrossFaderView(state: controller.crossFader)
                }
                .padding(.bottom, 6)
                .background(Color(UIColor.systemGray6))
            }
            .edgesIgnoringSafeArea([.top, .bottom])
        }
        .padding(.horizontal, 4) // 左右のみ少し離す
        .alert("リセット", isPresented: $showResetConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                controller.resetAllFaders()
            }
        } message: {
            Text("全てのフェーダーを0にしてリセットします。よろしいですか？")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .onAppear {
            if !hasShownAboutOnFirstLaunch {
                hasShownAboutOnFirstLaunch = true
                showAbout = true
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .all)
        .preferredColorScheme(.light)
    }
    
    // GeometryReaderからSafeAreaのTopを取得するヘルパー
    private func safeAreaTop(geometry: GeometryProxy) -> CGFloat {
        geometry.safeAreaInsets.top
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    private var copyrightYear: String {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear > 2025 ? "2025-\(currentYear)" : "2025"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("このアプリは、同志社高等学校のチャペル特設舞台の照明卓の機能を再現したアプリです。2025年度の2年生パート有志で制作したものです。")
                        .font(.body)
                    
                    Divider()
                    
                    Text("右端の下段 31チャンネル〜36チャンネル、上段67チャンネル〜72チャンネルはアプリでの表示を省略しています。")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("実際の照明卓では")
                            .font(.headline)
                        
                        Text("31ch, 67ch: 空き")
                        Text("32ch, 68ch: キャットウォーク間接照明")
                        Text("33ch, 69ch: 1階側面スポットライト")
                        Text("34ch, 70ch: 2階スポットライト")
                        Text("35ch, 71ch: 1階照明天井ライト")
                        Text("36ch, 72ch: ステージ天井ライト")
                    }
                    .padding(.leading, 8)
                    
                    Text("これらは照明卓下部の客電フェーダーで一括操作できるので、演劇の演出で使用する場合を除き、個別に操作する機会はほとんどありません。")
                        .font(.body)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("動画での解説(音響照明パート)")
                            .font(.headline)
                        Link("https://go.hunny.co.jp/dhs/light-yt", destination: URL(string: "https://go.hunny.co.jp/dhs/light-yt")!)
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Surface等で使用する場合")
                            .font(.headline)
                        Text("Web版チャペル照明シミュレーター")
                        Link("https://go.hunny.co.jp/dhs/light-web", destination: URL(string: "https://go.hunny.co.jp/dhs/light-web")!)
                            .foregroundColor(.blue)
                    }
                    
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("照明演出に関する問い合わせは音響･照明パートまで、このアプリに関する要望・問い合わせは以下からお願いします。")
                        Link("https://hunny.co.jp/contact", destination: URL(string: "https://hunny.co.jp/contact")!)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Spacer()
                        Text("©︎ \(copyrightYear) Kanata Tsuda. All Rights Reserved.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}
