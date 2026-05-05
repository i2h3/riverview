// SPDX-FileCopyrightText: 2026 Iva Horn
// SPDX-License-Identifier: MIT

import Foundation
import Rivers

///
/// Tails the active `log.jsonl` of a journal directory and decodes each newly-appended line into a `Message`. Owned by `JournalStore`, which provides callbacks that run on the main actor: `onAppend` for each new message, and `onRotate` when the file is renamed/deleted (the store responds with a full rescan).
///
/// Internally the watcher runs on a private `DispatchQueue` and uses two `DispatchSourceFileSystemObject` sources: one watching the active log file for writes/rotation, and one watching the directory so a freshly created log file is picked up after rotation.
///
nonisolated final class JournalWatcher: @unchecked Sendable {
    private let directory: URL
    private let queue: DispatchQueue
    private let onAppend: @MainActor (Message) -> Void
    private let onRotate: @MainActor () -> Void

    private var fileSource: DispatchSourceFileSystemObject?
    private var directorySource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var directoryDescriptor: Int32 = -1
    private var offset: UInt64 = 0
    private var carry: Data = .init()
    private let decoder = JSONDecoder()

    ///
    /// Create a watcher for the journal at `directory`. The callbacks are invoked on the main actor for every newly appended message and whenever the active log file rotates.
    ///
    init(directory: URL,
         onAppend: @escaping @MainActor (Message) -> Void,
         onRotate: @escaping @MainActor () -> Void)
    {
        self.directory = directory
        queue = DispatchQueue(label: "Riverview.JournalWatcher")
        self.onAppend = onAppend
        self.onRotate = onRotate
    }

    ///
    /// Begin tailing. `initialOffset` is the byte offset to start reading from in the active log file; `JournalStore` passes the current file size so existing content (already loaded via `FileJournalReader`) is not redelivered.
    ///
    func start(initialOffset: UInt64) {
        queue.async { [weak self] in
            self?.openFile(initialOffset: initialOffset)
            self?.openDirectory()
        }
    }

    ///
    /// Cancel both dispatch sources and close their file descriptors. Safe to call repeatedly.
    ///
    func stop() {
        queue.async { [weak self] in
            self?.closeFile()
            self?.closeDirectory()
        }
    }

    deinit {
        fileSource?.cancel()
        directorySource?.cancel()
        if fileDescriptor >= 0 { close(fileDescriptor) }
        if directoryDescriptor >= 0 { close(directoryDescriptor) }
    }

    private var activeURL: URL {
        directory.appendingPathComponent("log.jsonl")
    }

    private func openFile(initialOffset: UInt64) {
        closeFile()

        let path = activeURL.path
        let fd = open(path, O_RDONLY | O_EVTONLY)

        guard fd >= 0 else {
            return
        }

        fileDescriptor = fd
        offset = initialOffset
        carry.removeAll(keepingCapacity: true)

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }

            let event = source.data

            if event.contains(.rename) || event.contains(.delete) {
                handleRotation()
                return
            }

            drain()
        }

        source.setCancelHandler { [fd] in
            close(fd)
        }

        fileSource = source
        source.resume()

        drain()
    }

    private func closeFile() {
        fileSource?.cancel()
        fileSource = nil
        fileDescriptor = -1
        offset = 0
        carry.removeAll(keepingCapacity: false)
    }

    private func openDirectory() {
        closeDirectory()

        let fd = open(directory.path, O_RDONLY | O_EVTONLY)

        guard fd >= 0 else {
            return
        }

        directoryDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.handleDirectoryChange()
        }

        source.setCancelHandler { [fd] in
            close(fd)
        }

        directorySource = source
        source.resume()
    }

    private func closeDirectory() {
        directorySource?.cancel()
        directorySource = nil
        directoryDescriptor = -1
    }

    private func drain() {
        guard fileDescriptor >= 0 else { return }

        let handle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: false)

        do {
            try handle.seek(toOffset: offset)
        } catch {
            return
        }

        let data = handle.availableData

        guard !data.isEmpty else { return }

        offset += UInt64(data.count)

        var buffer = carry
        buffer.append(data)

        var start = buffer.startIndex

        while let lineEnd = buffer[start...].firstIndex(of: 0x0A) {
            let line = buffer[start ..< lineEnd]

            if !line.isEmpty {
                if let message = try? decoder.decode(Message.self, from: Data(line)) {
                    DispatchQueue.main.async { [onAppend] in
                        MainActor.assumeIsolated {
                            onAppend(message)
                        }
                    }
                }
            }

            start = buffer.index(after: lineEnd)
        }

        carry = Data(buffer[start...])
    }

    private func handleRotation() {
        DispatchQueue.main.async { [onRotate] in
            MainActor.assumeIsolated {
                onRotate()
            }
        }

        openFile(initialOffset: 0)
    }

    private func handleDirectoryChange() {
        let exists = FileManager.default.fileExists(atPath: activeURL.path)

        if exists, fileDescriptor < 0 {
            openFile(initialOffset: 0)
        }
    }
}
