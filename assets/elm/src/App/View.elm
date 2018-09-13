module App.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.HtmlUtil exposing (faIcon, materialIcon)
import Util.EventUtil exposing (onLinkButtonClick)
import App.Types.Session exposing (Session)
import App.Types.Traversal
import App.Types.SearchResults
import App.ActiveViewOnMobile exposing (ActiveViewOnMobile(..))
import App.Messages exposing (..)
import App.Model exposing (..)
import App.Submodels.LocalCotos
import App.Submodels.Modals exposing (Modal(..))
import App.Views.AppHeader
import App.Views.Navigation
import App.Views.Flow
import App.Views.Stock
import App.Views.Traversals
import App.Views.CotoSelection
import App.Views.SearchResults
import App.Modals.ConnectModal
import App.Modals.ProfileModal
import App.Modals.InviteModal
import App.Modals.CotoMenuModal
import App.Modals.CotoModal
import App.Modals.SigninModal
import App.Modals.EditorModal
import App.Modals.ConfirmModal
import App.Modals.ImportModal
import App.Modals.TimelineFilterModal


view : Model -> Html Msg
view model =
    let
        activeViewOnMobile =
            case model.activeViewOnMobile of
                TimelineView ->
                    "timeline"

                PinnedView ->
                    "pinned"

                TraversalsView ->
                    "traversals"

                SelectionView ->
                    "selection"

                SearchResultsView ->
                    "search-results"
    in
        div
            [ id "app"
            , classList
                [ ( "cotonomas-loading", model.cotonomasLoading )
                , ( activeViewOnMobile ++ "-view-on-mobile", True )
                ]
            , onClick AppClick
            ]
            [ App.Views.AppHeader.view model
            , div [ id "app-body" ]
                [ div [ id "app-layout" ]
                    [ navColumn model
                    , flowColumn model
                    , graphExplorationDiv model
                    , selectionColumn model
                    , searchResultsColumn model
                    , viewSwitchContainerDiv model
                    ]
                ]
            , App.Views.CotoSelection.statusBar model
            , div [] (modals model)
            ]


navColumn : Model -> Html Msg
navColumn model =
    div
        [ id "main-nav"
        , classList
            [ ( "neverToggled", not model.navigationToggled )
            , ( "empty", App.Submodels.LocalCotos.isNavigationEmpty model )
            , ( "notEmpty", not (App.Submodels.LocalCotos.isNavigationEmpty model) )
            , ( "animated", model.navigationToggled )
            , ( "slideInDown", model.navigationToggled && model.navigationOpen )
            , ( "slideOutUp", model.navigationToggled && not model.navigationOpen )
            ]
        ]
        (App.Views.Navigation.view model)


graphExplorationDiv : Model -> Html Msg
graphExplorationDiv model =
    div
        [ id "graph-exploration"
        , classList
            [ ( "activeOnMobile"
              , List.member model.activeViewOnMobile [ PinnedView, TraversalsView ]
              )
            , ( "timeline-hidden", model.timeline.hidden )
            ]
        ]
        (openFlowButton model
            :: stockColumn model
            :: traversalColumns model
        )


openFlowButton : Model -> Html Msg
openFlowButton model =
    if model.timeline.hidden then
        div [ id "open-flow" ]
            [ a
                [ class "tool-button flow-toggle"
                , title "Open flow view"
                , onLinkButtonClick ToggleTimeline
                ]
                [ materialIcon "chat" Nothing ]
            ]
    else
        Util.HtmlUtil.none


flowColumn : Model -> Html Msg
flowColumn model =
    model.session
        |> Maybe.map
            (\session ->
                if model.timeline.hidden then
                    flowDiv
                        session
                        [ ( "main-column", True )
                        , ( "hidden", True )
                        ]
                        model
                else
                    let
                        active =
                            model.activeViewOnMobile == TimelineView
                    in
                        flowDiv
                            session
                            [ ( "main-column", True )
                            , ( "activeOnMobile", active )
                            , ( "animated", active )
                            , ( "fadeIn", active )
                            ]
                            model
            )
        |> Maybe.withDefault Util.HtmlUtil.none


flowDiv : Session -> List ( String, Bool ) -> Model -> Html Msg
flowDiv session classes model =
    div
        [ id "main-flow"
        , classList classes
        ]
        [ App.Views.Flow.view model session model ]


stockColumn : Model -> Html Msg
stockColumn model =
    div
        [ id "main-stock"
        , classList
            [ ( "main-column", True )
            , ( "empty", List.isEmpty model.graph.rootConnections )
            , ( "activeOnMobile", model.activeViewOnMobile == PinnedView )
            , ( "animated", model.activeViewOnMobile == PinnedView )
            , ( "fadeIn", model.activeViewOnMobile == PinnedView )
            ]
        ]
        [ App.Views.Stock.view model model
        ]


traversalColumns : Model -> List (Html Msg)
traversalColumns model =
    App.Views.Traversals.view
        (model.activeViewOnMobile == TraversalsView)
        model
        model.graph
        model.traversals


selectionColumn : Model -> Html Msg
selectionColumn model =
    div
        [ id "main-selection"
        , classList
            [ ( "main-column", True )
            , ( "activeOnMobile", model.activeViewOnMobile == SelectionView )
            , ( "animated", True )
            , ( "fadeIn", not (List.isEmpty model.selection) )
            , ( "empty", List.isEmpty model.selection )
            , ( "hidden", not model.cotoSelectionColumnOpen )
            ]
        ]
        [ App.Views.CotoSelection.cotoSelectionColumnDiv model
        ]


searchResultsColumn : Model -> Html Msg
searchResultsColumn model =
    div
        [ id "main-search-results"
        , classList
            [ ( "main-column", True )
            , ( "activeOnMobile", model.activeViewOnMobile == SearchResultsView )
            , ( "animated", True )
            , ( "fadeIn", App.Types.SearchResults.hasQuery model.searchResults )
            , ( "hidden", not (App.Types.SearchResults.hasQuery model.searchResults) )
            ]
        ]
        [ App.Views.SearchResults.view model model.graph model.searchResults
        ]


viewSwitchContainerDiv : Model -> Html Msg
viewSwitchContainerDiv model =
    div
        [ id "view-switch-container" ]
        [ viewSwitchDiv
            "switch-to-timeline"
            "comments"
            "Switch to timeline"
            (model.activeViewOnMobile == TimelineView)
            False
            (SwitchViewOnMobile TimelineView)
        , viewSwitchDiv
            "switch-to-pinned"
            "thumb-tack"
            "Switch to pinned cotos"
            (model.activeViewOnMobile == PinnedView)
            (App.Submodels.LocalCotos.isStockEmpty model)
            (SwitchViewOnMobile PinnedView)
        , viewSwitchDiv
            "switch-to-traversals"
            "sitemap"
            "Switch to explorations"
            (model.activeViewOnMobile == TraversalsView)
            (App.Types.Traversal.isEmpty model.traversals)
            (SwitchViewOnMobile TraversalsView)
        , viewSwitchDiv
            "switch-to-selection"
            "check-square-o"
            "Switch to coto selection"
            (model.activeViewOnMobile == SelectionView)
            (List.isEmpty model.selection)
            (SwitchViewOnMobile SelectionView)
        , viewSwitchDiv
            "switch-to-search"
            "search"
            "Switch to search cotos"
            (model.activeViewOnMobile == SearchResultsView)
            False
            (SwitchViewOnMobile SearchResultsView)
        ]


viewSwitchDiv : String -> String -> String -> Bool -> Bool -> Msg -> Html Msg
viewSwitchDiv divId iconName buttonTitle selected empty onClickMsg =
    div
        [ id divId
        , classList
            [ ( "view-switch", True )
            , ( "selected", selected )
            , ( "empty", empty )
            ]
        ]
        [ if selected || empty then
            span
                [ class "tool-button" ]
                [ faIcon iconName Nothing ]
          else
            a
                [ class "tool-button"
                , title buttonTitle
                , onClick onClickMsg
                ]
                [ faIcon iconName Nothing ]
        ]


modals : Model -> List (Html Msg)
modals model =
    List.map
        (\modal ->
            case modal of
                ConfirmModal ->
                    App.Modals.ConfirmModal.view model.confirmation.message

                SigninModal ->
                    App.Modals.SigninModal.view model.signinModal

                EditorModal ->
                    App.Modals.EditorModal.view model model.editorModal

                ProfileModal ->
                    App.Modals.ProfileModal.view model.session

                InviteModal ->
                    App.Modals.InviteModal.view model.inviteModal

                CotoMenuModal ->
                    App.Modals.CotoMenuModal.view model model.graph model.cotoMenuModal

                CotoModal ->
                    App.Modals.CotoModal.view model.session model.cotoModal

                ConnectModal ->
                    App.Modals.ConnectModal.view
                        (App.Submodels.LocalCotos.getSelectedCotos model model)
                        model.connectModal

                ImportModal ->
                    App.Modals.ImportModal.view model.importModal

                TimelineFilterModal ->
                    App.Modals.TimelineFilterModal.view model model.timeline.filter
        )
        (List.reverse model.modals)
