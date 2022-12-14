//
//  ContentView.swift
//  Target
//
//  Created by Fadey Notchenko on 26.08.2022.
//

import SwiftUI
import StoreKit
import Lottie

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)]) var targets: FetchedResults<Target>
    
    @State private var showNewTargetView = false
    @State private var showProVersionView = false
    
    @State private var id: UUID?
    
    @AppStorage("VN.Target.fullversion") var fullVersion = false
    
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        GeometryReader { reader in
            NavigationView {
                ZStack {
                    List {
                        //archiveButton
                        
                        targetList
                    }
                }
                .listStyle(.plain)
                .navigationTitle(Text("Моя Копилка"))
                .sheet(isPresented: $showNewTargetView) {
                    NewTargetView(showNewTargetView: $showNewTargetView)
                }
                .sheet(isPresented: $showProVersionView) {
                    ProVersion(showProVersionView: $showProVersionView, showNewTargetView: $showNewTargetView)
                }
                .toolbar {
                    ToolbarItem {
                        showNewTargetViewButton
                    }
                    
                }
                
                Text("Выберите цель из списка")
            }
            .currentNavigationStyle(width: reader.size.width)
        }
    }
    
    @ViewBuilder
    private var targetList: some View {
        if Constants.IDIOM == .pad {
            ForEach(targets.filter({ $0.isFinished == false })) { target in
                NavigationLink(tag: target.id ?? UUID(), selection: $vm.id) {
                    TargetDetailView(target: target)
                } label: {
                    TargetRow(target: target)
                }
                .swipeActions {
                    deleteButton(target)
                }
            }
        } else {
            ForEach(targets.filter({ $0.isFinished == false })) { target in
                NavigationLink {
                    TargetDetailView(target: target)
                } label: {
                    TargetRow(target: target)
                }
                .swipeActions {
                    deleteButton(target)
                }
            }
        }
    }
    
    private var showNewTargetViewButton: some View {
        Button {
            if targets.filter( { $0.isFinished == false }).count > 0 && vm.purchased.isEmpty {
                showProVersionView = true
            } else {
                showNewTargetView = true
            }
        } label: {
            Image(systemName: "plus")
        }
    }
    
    private var archiveButton: some View {
        NavigationLink {
            ArchiveTargetsView()
        } label: {
            Label {
                HStack(spacing: 5) {
                    Text("Архив")
                        .bold()
                    
                    Text("(\(targets.filter( { $0.isFinished }).count))")
                        .bold()
                }
            } icon: {
                Image(systemName: "archivebox.fill")
            }
            .font(.title3)
            .foregroundColor(.gray)
            .padding(.vertical)
        }
    }
    
    private func deleteButton(_ target: Target) -> some View {
        Button(role: .destructive) {
            NotificationHandler.deleteNotification(by: target.id?.uuidString ?? UUID().uuidString)
            
            withAnimation {
                PersistenceController.deleteTarget(target: target, context: viewContext)
            }
        } label: {
            Image(systemName: "trash")
        }
    }
}

struct ProVersion: View {
    
    @Binding var showProVersionView: Bool
    @Binding var showNewTargetView: Bool
    
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Для создания больше одной цели - требуется доступ к полной версии приложения")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button {
                    Task {
                        let bool = await vm.purchase()
                        
                        if bool {
                            dismiss()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showNewTargetView = true
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("Купить")
                            .bold()
                        
                        if let product = vm.products.first {
                            Text(product.displayPrice)
                                .bold()
                        }
                    }
                }
                .padding()
                .background(Color("Color"))
                .cornerRadius(15)
                
                Text("Покупка полной версии осуществляется один раз!")
                    .padding()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .navigationTitle(Text("PRO Версия"))
            .toolbar {
                ToolbarItem {
                    Button("Закрыть") {
                        showProVersionView = false
                    }
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func currentNavigationStyle(width: CGFloat) -> some View {
        if Constants.IDIOM == .pad && width > 400 {
            self.navigationViewStyle(.automatic)
        } else {
            self.navigationViewStyle(.stack)
        }
    }
}

extension UINavigationController {
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}

