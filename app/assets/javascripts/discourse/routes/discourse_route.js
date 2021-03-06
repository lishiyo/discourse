/**
  The base route for all routes on Discourse. Includes global enter functionality.

  @class Route
  @extends Em.Route
  @namespace Discourse
  @module Discourse
**/
Discourse.Route = Em.Route.extend({

  /**
    NOT called every time we enter a route on Discourse.
    Only called the FIRST time we enter a route.
    So, when going from one topic to another, activate will only be called on the
    TopicRoute for the first topic.

    @method activate
  **/
  activate: function() {
    this._super();
    Em.run.scheduleOnce('afterRender', Discourse.Route, 'cleanDOM');
  },

  redirectIfLoginRequired: function() {
    var app = this.controllerFor('application');
    if (app.get('loginRequired')) {
      this.replaceWith('login');
    }
  },

  openTopicDraft: function(model){
    // If there's a draft, open the create topic composer
    if (model.draft) {
      var composer = this.controllerFor('composer');
      if (!composer.get('model.viewOpen')) {
        composer.open({
          action: Discourse.Composer.CREATE_TOPIC,
          draft: model.draft,
          draftKey: model.draft_key,
          draftSequence: model.draft_sequence
        });
      }
    }
  }

});

var routeBuilder;

Discourse.Route.reopenClass({

  buildRoutes: function(builder) {
    var oldBuilder = routeBuilder;
    routeBuilder = function() {
      if (oldBuilder) oldBuilder.call(this);
      return builder.call(this);
    };
  },

  mapRoutes: function() {
    Discourse.Router.map(function() {
      routeBuilder.call(this);
      this.route('unknown', {path: '*path'});
    });
  },

  cleanDOM: function() {
    // Close mini profiler
    $('.profiler-results .profiler-result').remove();

    // Close some elements that may be open
    $('.d-dropdown').hide();
    $('header ul.icons li').removeClass('active');
    $('[data-toggle="dropdown"]').parent().removeClass('open');
    // close the lightbox
    if ($.magnificPopup && $.magnificPopup.instance) { $.magnificPopup.instance.close(); }

    // Remove any link focus
    // NOTE: the '.not("body")' is here to prevent a bug in IE10 on Win7
    // cf. https://stackoverflow.com/questions/5657371/ie9-window-loses-focus-due-to-jquery-mobile
    $(document.activeElement).not("body").blur();

    Discourse.set('notifyCount',0);
    $('#discourse-modal').modal('hide');
    var hideDropDownFunction = $('html').data('hide-dropdown');
    if (hideDropDownFunction) { hideDropDownFunction(); }

    // TODO: Avoid container lookup here
    var appEvents = Discourse.__container__.lookup('app-events:main');
    appEvents.trigger('dom:clean');
  },

  /**
    Shows a modal

    @method showModal
  **/
  showModal: function(router, name, model) {
    router.controllerFor('modal').set('modalClass', null);
    router.render(name, {into: 'modal', outlet: 'modalBody'});
    var controller = router.controllerFor(name);
    if (controller) {
      if (model) {
        controller.set('model', model);
      }
      if(controller && controller.onShow) {
        controller.onShow();
      }
      controller.set('flashMessage', null);
    }
  }

});
