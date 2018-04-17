const $ = require('jquery');
const _ = require('underscore');
const Backbone = require('backbone');
const ProfileFormView = require('dashboard/views/profile/profile-form/profile-form-view');
const UserModel = require('dashboard/data/user-model');

const DISPLAY_EMAIL = 'admin@carto.com';
const DESCRIPTION = 'description';
const AVATAR_URL = 'avatar_url';
const NAME = 'name';
const LAST_NAME = 'last_name';
const WEBSITE = 'website';
const TWITTER_USERNAME = 'twitter_username';
const DISQUS_SHORTNAME = 'disqus_shortname';
const AVAILABLE_FOR_HIRE = true;
const LOCATION = 'location';

describe('profile/profile_form_view', function () {
  let userModel, model, configModel, view, setLoadingSpy, showSuccessSpy, showErrorsSpy;

  const createViewFn = function (options) {
    userModel = new UserModel(
      _.extend({
        username: 'pepe',
        base_url: 'http://pepe.carto.com',
        email: 'pepe@carto.com',
        account_type: 'FREE',
        description: DESCRIPTION,
        avatar_url: AVATAR_URL,
        name: NAME,
        last_name: LAST_NAME,
        website: WEBSITE,
        twitter_username: TWITTER_USERNAME,
        disqus_shortname: DISQUS_SHORTNAME,
        available_for_hire: AVAILABLE_FOR_HIRE,
        location: LOCATION,
        viewer: false
      }, options)
    );

    setLoadingSpy = jasmine.createSpy('setLoading');
    showSuccessSpy = jasmine.createSpy('showSuccess');
    showErrorsSpy = jasmine.createSpy('showErrors');

    model = new Backbone.Model();

    configModel = new Backbone.Model({
      avatar_valid_extensions: ['jpeg', 'jpg', 'gif', 'png']
    });
    configModel.prefixUrl = () => '';

    const view = new ProfileFormView({
      userModel,
      configModel,
      setLoading: setLoadingSpy,
      onSaved: showSuccessSpy,
      onError: showErrorsSpy,
      renderModel: model
    });

    return view;
  };

  beforeEach(function () {
    view = createViewFn();
  });

  describe('.render', function () {
    it('should render properly', function () {
      view.render();

      expect(view.$el.html()).toContain('<form accept-charset="UTF-8" action="/profile" method="post">');
      expect(view.$el.html()).toContain('<div class="CDB-Text js-avatarSelector FormAccount-avatarSelector">');
      expect(view.$el.html()).toContain('<input class="CDB-InputText CDB-Text FormAccount-input FormAccount-input--small u-rspace-s" id="user_name" name="user[name]" placeholder="profile.views.form.first_name" size="30" type="text" value="' + NAME + '">');
      expect(view.$el.html()).toContain('<input class="CDB-InputText CDB-Text FormAccount-input FormAccount-input--small" id="user_last_name" name="user[last_name]" placeholder="profile.views.form.last_name" size="30" type="text" value="' + LAST_NAME + '">');
      expect(view.$el.html()).toContain('<input class="CDB-InputText CDB-Text FormAccount-input FormAccount-input--med" id="user_website" name="user[website]" size="30" type="text" value="' + WEBSITE + '">');
      expect(view.$el.html()).toContain('<input class="CDB-InputText CDB-Text FormAccount-input FormAccount-input--med" id="user_location" name="user[location]" size="30" type="text" value="' + LOCATION + '">');
      expect(view.$el.html()).toContain('<textarea class="CDB-Textarea CDB-Text FormAccount-textarea FormAccount-input FormAccount-input--totalwidth" cols="40" id="user_description" name="user[description]" rows="20">' + DESCRIPTION + '</textarea>');
      expect(view.$el.html()).toContain('<input class="CDB-InputText CDB-Text FormAccount-input FormAccount-input--med" id="user_twitter_username" name="user[twitter_username]" size="30" type="text" value="' + TWITTER_USERNAME + '">');
      expect(view.$el.html()).toContain('<input class="CDB-InputText CDB-Text FormAccount-input FormAccount-input--med" id="user_disqus_shortname" name="user[disqus_shortname]" placeholder="profile.views.form.disqus_placeholder" size="30" type="text" value="' + DISQUS_SHORTNAME + '">');
      expect(view.$el.html()).toContain('<input name="user[available_for_hire]" type="hidden" value="0"><input id="available_for_hire" name="user[available_for_hire]" type="checkbox" value="' + AVAILABLE_FOR_HIRE + '" checked="checked">');
      expect(view.$el.html()).toContain('profile.views.form.builder');
      expect(view.$el.html()).toContain('profile.views.form.write_access');
    });
  });

  describe('is viewer', function () {
    beforeEach(function () {
      userModel.set('viewer', true);
    });

    describe('.render', function () {
      it('should render properly', function () {
        view.render();

        expect(view.$el.html()).toContain('profile.views.form.viewer');
        expect(view.$el.html()).toContain('profile.views.form.read_only');
      });
    });
  });

  describe('is inside org', function () {
    beforeEach(function () {
      spyOn(userModel, 'isInsideOrg').and.returnValue(true);
    });

    describe('.render', function () {
      it('should render properly', function () {
        spyOn(userModel, 'isViewer').and.returnValue(true);
        spyOn(view, '_getOrgAdminEmail').and.returnValue(DISPLAY_EMAIL);

        view.render();

        expect(view.$el.html()).toContain(`<a href="mailto:${DISPLAY_EMAIL}">profile.views.form.become_builder</a>`);
      });
    });

    describe('._getOrgAdminEmail', function () {
      it('should get org admin email', function () {
        userModel.organization = {
          display_email: DISPLAY_EMAIL
        };

        expect(view._getOrgAdminEmail()).toBe(DISPLAY_EMAIL);
      });
    });
  });

  describe('._getOrgAdminEmail', function () {
    it('should return null', function () {
      expect(view._getOrgAdminEmail()).toBeNull();
    });
  });

  describe('._initModels', function () {
    it('should init models', function () {
      expect(view._userModel).toBe(userModel);
      expect(view._configModel).toBe(configModel);
      expect(view._renderModel).toEqual(model);
    });
  });

  describe('._initViews', function () {
    it('should init views', function () {
      view.render();

      expect(_.size(view._subviews)).toBe(1);
    });
  });

  describe('._getUserFields', function () {
    it('should get user fields', function () {
      expect(view._getUserFields()).toEqual({
        description: DESCRIPTION,
        avatar_url: AVATAR_URL,
        name: NAME,
        last_name: LAST_NAME,
        website: WEBSITE,
        twitter_username: TWITTER_USERNAME,
        disqus_shortname: DISQUS_SHORTNAME,
        available_for_hire: AVAILABLE_FOR_HIRE,
        location: LOCATION
      });
    });
  });

  describe('._getDestinationValues', function () {
    const destDescription = '_description';
    const destAvatarUrl = '_avatar';
    const destName = '_name';
    const destLastName = '_last_name';
    const destWebsite = '_website';
    const destTwitterUsername = '_twitter_username';
    const destDisqusShortname = '_disqus_shortname';
    const destAvailableForHire = false;
    const destLocation = '_location';

    it('should get destination values', function () {
      view = createViewFn({
        description: destDescription,
        avatar_url: destAvatarUrl,
        name: destName,
        last_name: destLastName,
        website: destWebsite,
        twitter_username: destTwitterUsername,
        disqus_shortname: destDisqusShortname,
        available_for_hire: destAvailableForHire,
        location: destLocation
      });

      view.render();

      expect(view._getDestinationValues()).toEqual({
        description: destDescription,
        avatar_url: destAvatarUrl,
        name: destName,
        last_name: destLastName,
        website: destWebsite,
        twitter_username: destTwitterUsername,
        disqus_shortname: destDisqusShortname,
        available_for_hire: destAvailableForHire,
        location: destLocation
      });
    });
  });

  describe('._onClickSave', function () {
    it('should save user', function () {
      const destName = 'Carlos';
      const event = $.Event('click');

      spyOn(view, 'killEvent');
      spyOn(view, '_getUserFields').and.returnValue({
        name: NAME
      });
      spyOn(view, '_getDestinationValues').and.returnValue({
        name: destName
      });
      spyOn(view._userModel, 'save');

      view._onClickSave(event);

      expect(view.killEvent).toHaveBeenCalledWith(event);
      expect(view._userModel.save).toHaveBeenCalledWith({
        user: {
          name: destName
        }
      }, {
        wait: true,
        url: '/api/v3/me',
        success: showSuccessSpy,
        error: showErrorsSpy
      });
    });
  });

  it('should not have leaks', function () {
    view.render();

    expect(view).toHaveNoLeaks();
  });

  afterEach(function () {
    view.clean();
  });
});