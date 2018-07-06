//
//  RxApollo.swift
//  RxApollo
//
//  Created by Scott Hoyt on 5/9/17.
//  Copyright © 2017 Scott Hoyt. All rights reserved.
//

import Foundation
import RxSwift
import Apollo

/// An `Error` emitted by `ApolloReactiveExtensions`.
public enum RxApolloError: Error {
    /// One or more `GraphQLError`s were encountered.
    case graphQLErrors([GraphQLError])
    case unknown
}

/// Reactive extensions for `ApolloClient`.
extension Reactive where Base: ApolloClient {

    /// Fetches a query from the server or from the local cache, depending on the current contents of the cache and the specified cache policy.
    ///
    /// - Parameters:
    ///   - query: The query to fetch.
    ///   - cachePolicy: A cache policy that specifies when results should be fetched from the server and when data should be loaded from the local cache.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    /// - Returns: A `Maybe` that emits the results of the query.
    public func fetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .returnCacheDataElseFetch,
        queue: DispatchQueue = DispatchQueue.main) -> Single<Query.Data?> {
        return .create { single in
            let cancellable = self.base.fetch(query: query, cachePolicy: cachePolicy, queue: queue) { result, error in
                if let error = error {
                    single(.error(error))
                } else if let errors = result?.errors {
                    single(.error(RxApolloError.graphQLErrors(errors)))
                } else if let result = result {
                    single(.success(result.data))
                } else {
                  single(.error(RxApolloError.unknown))
                }
            }

            return Disposables.create(with: cancellable.cancel)
        }
    }

    /// Watches a query by first fetching an initial result from the server or from the local cache, depending on the current contents of the cache and the specified cache policy. After the initial fetch, the returned `Observable` will emit events whenever any of the data the query result depends on changes in the local cache.
    ///
    /// - Parameters:
    ///   - query: The query to watch.
    ///   - cachePolicy: A cache policy that specifies when results should be fetched from the server or from the local cache.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    /// - Returns: An `Observable` that emits the results of watching the `query`.
    public func watch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .returnCacheDataElseFetch,
        queue: DispatchQueue = DispatchQueue.main) -> Observable<Query.Data?> {
        return Observable.create { observer in
            let watcher = self.base.watch(query: query, cachePolicy: cachePolicy, queue: queue) { result, error in
                if let error = error {
                    observer.onError(error)
                } else if let errors = result?.errors {
                    observer.onError(RxApolloError.graphQLErrors(errors))
                } else {
                    observer.onNext(result?.data)
                }
            }

          return Disposables.create(with: watcher.cancel)
        }
    }

    /// Performs a mutation by sending it to the server.
    ///
    /// - Parameters:
    ///   - mutation: The mutation to perform.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    /// - Returns: A `Maybe` that emits the results of the mutation.
    public func perform<Mutation: GraphQLMutation>(mutation: Mutation, queue: DispatchQueue = DispatchQueue.main) -> Single<Mutation.Data?> {
        return .create { single in
            let cancellable = self.base.perform(mutation: mutation, queue: queue) { result, error in
                if let error = error {
                    single(.error(error))
                } else if let errors = result?.errors {
                    single(.error(RxApolloError.graphQLErrors(errors)))
                } else if let result = result {
                    single(.success(result.data))
                } else {
                    single(.error(RxApolloError.unknown))
                }
            }

          return Disposables.create(with: cancellable.cancel)
        }
    }
}

extension ApolloClient: ReactiveCompatible {}
