import KsApi
import KsLive
import ReactiveCocoa
import ReactiveExtensions
import Result
import Prelude

public protocol LiveStreamContainerViewModelType {
  var inputs: LiveStreamContainerViewModelInputs { get }
  var outputs: LiveStreamContainerViewModelOutputs { get }
}

public protocol LiveStreamContainerViewModelInputs {
  func configureWith(project project: Project, event: LiveStreamEvent?)
  func closeButtonTapped()
  func setLiveStreamEvent(event event: LiveStreamEvent)
  func viewDidLoad()
  func liveStreamViewControllerStateChanged(state state: LiveStreamViewControllerState)
}

public protocol LiveStreamContainerViewModelOutputs {
  var createAndConfigureLiveStreamViewController: Signal<(Project, LiveStreamEvent), NoError> { get }
  var dismiss: Signal<(), NoError> { get }
  var liveStreamState: Signal<LiveStreamViewControllerState, NoError> { get }
  var loaderText: Signal<String, NoError> { get }
  var projectImageUrl: Signal<NSURL, NoError> { get }
  var showVideoView: Signal<Bool, NoError> { get }
  var titleViewText: Signal<String, NoError> { get }
}

public final class LiveStreamContainerViewModel: LiveStreamContainerViewModelType,
LiveStreamContainerViewModelInputs, LiveStreamContainerViewModelOutputs {

  //swiftlint:disable function_body_length
  public init() {
    let project = combineLatest(
      self.projectProperty.signal.ignoreNil(),
      self.viewDidLoadProperty.signal)
      .map(first)

    self.createAndConfigureLiveStreamViewController = combineLatest(
      self.projectProperty.signal.ignoreNil(),
      self.liveStreamEventProperty.signal.ignoreNil(),
      self.viewDidLoadProperty.signal
      ).map { a, b, _ in (a, b) }

    self.liveStreamState = Signal.merge(
      self.liveStreamViewControllerStateChangedProperty.signal.ignoreNil(),
      project.mapConst(.loading)
    )

    self.loaderText = liveStreamState.map {
        if case .live(playbackState: .loading, _) = $0 { return localizedString(
          key: "The_live_stream_will_start_soon", defaultValue: "The live stream will start soon")
        }
        if case .greenRoom = $0 { return localizedString(
          key: "The_live_stream_will_start_soon", defaultValue: "The live stream will start soon")
        }
        if case .replay(playbackState: .loading, _, _) = $0 { return localizedString(
          key: "The_replay_will_start_soon", defaultValue: "The replay will start soon")
        }

      return localizedString(key: "Loading", defaultValue: "Loading")
    }

    self.projectImageUrl = project
      .map { NSURL(string: $0.photo.full) }
      .ignoreNil()

    self.titleViewText = liveStreamState.map {
      if case .live(_, _) = $0 { return localizedString(key: "Live", defaultValue: "Live") }
      if case .greenRoom = $0 { return localizedString(key: "Starting_soon", defaultValue: "Starting soon") }
      if case .replay(_, _, _) = $0 { return localizedString(
        key: "Recorded_Live", defaultValue: "Recorded Live") }

      return localizedString(key: "Loading", defaultValue: "Loading")
    }

    self.showVideoView = combineLatest(
        self.liveStreamViewControllerStateChangedProperty.signal.ignoreNil().map {
          if case .live(playbackState: .playing, _) = $0 { return true }
          if case .replay(playbackState: .playing, _, _) = $0 { return true }

          return false
        },
        self.createAndConfigureLiveStreamViewController
    ).map(first)

    self.dismiss = self.closeButtonTappedProperty.signal
  }

  private let projectProperty = MutableProperty<Project?>(nil)
  public func configureWith(project project: Project, event: LiveStreamEvent?) {
    self.projectProperty.value = project
    self.liveStreamEventProperty.value = event
  }

  private let closeButtonTappedProperty = MutableProperty()
  public func closeButtonTapped() {
    self.closeButtonTappedProperty.value = ()
  }

  private let liveStreamViewControllerStateChangedProperty =
    MutableProperty<LiveStreamViewControllerState?>(nil)
  public func liveStreamViewControllerStateChanged(state state: LiveStreamViewControllerState) {
    self.liveStreamViewControllerStateChangedProperty.value = state
  }

  private let liveStreamEventProperty = MutableProperty<LiveStreamEvent?>(nil)
  public func setLiveStreamEvent(event event: LiveStreamEvent) {
    self.liveStreamEventProperty.value = event
  }

  private let viewDidLoadProperty = MutableProperty()
  public func viewDidLoad() {
    self.viewDidLoadProperty.value = ()
  }

  public let createAndConfigureLiveStreamViewController: Signal<(Project, LiveStreamEvent), NoError>
  public let dismiss: Signal<(), NoError>
  public let liveStreamState: Signal<LiveStreamViewControllerState, NoError>
  public let loaderText: Signal<String, NoError>
  public let projectImageUrl: Signal<NSURL, NoError>
  public let showVideoView: Signal<Bool, NoError>
  public let titleViewText: Signal<String, NoError>

  public var inputs: LiveStreamContainerViewModelInputs { return self }
  public var outputs: LiveStreamContainerViewModelOutputs { return self }
}