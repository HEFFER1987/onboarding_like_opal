//
//  LocationMapSearchOverlay.swift
//  TestOnboardingChat
//

import SwiftUI

struct LocationMapSearchBar: View {
    @Bindable var viewModel: LocationPickerViewModel
    var isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))

            TextField("Search", text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.updateSearchQuery($0) }
            ))
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .focused(isSearchFocused)
            .submitLabel(.search)
            .onSubmit {
                viewModel.submitSearchQuery()
            }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                    isSearchFocused.wrappedValue = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        // .frame(maxWidth: 188)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
        .onChange(of: isSearchFocused.wrappedValue) { _, isFocused in
            viewModel.handleSearchFocusChanged(isFocused)
        }
        .onChange(of: viewModel.isSearchFieldFocused) { _, isFocused in
            if isFocused != isSearchFocused.wrappedValue {
                isSearchFocused.wrappedValue = isFocused
            }
        }
    }
}

struct LocationMapSearchResultsPanel: View {
    @Bindable var viewModel: LocationPickerViewModel
    var resultsMaxHeight: CGFloat
    var onSelectResult: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isSearchingLocations {
                    loadingRow
                } else if viewModel.searchResults.isEmpty, !viewModel.searchQuery.isEmpty {
                    emptyRow
                } else {
                    ForEach(viewModel.searchResults) { result in
                        resultRow(result)
                    }
                }
            }
        }
        .frame(maxHeight: resultsMaxHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }

    private func resultRow(_ result: LocationSearchResult) -> some View {
        Button {
            viewModel.selectSearchResult(result)
            onSelectResult()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result.kind == .venue ? "building.2.fill" : "mappin.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LocationPickerColors.accent)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let subtitle = result.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.white.opacity(0.6))
            Text("Searching…")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }

    private var emptyRow: some View {
        Text("No places found")
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
    }
}
