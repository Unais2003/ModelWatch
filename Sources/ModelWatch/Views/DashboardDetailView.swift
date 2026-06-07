import SwiftUI

struct DashboardDetailView: View {
    let destination: AppDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(destination.title, systemImage: destination.systemImage)
                .font(.title2)
                .fontWeight(.semibold)

            Text("This surface is ready for the \(destination.title.lowercased()) feature.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(32)
        .navigationTitle(destination.title)
    }
}
