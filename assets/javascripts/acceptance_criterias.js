function AcceptanceCriteriaForm(data)
{
    var self = this;
    self.criterias = ko.observableArray(ko.utils.arrayMap(data, function(criteria) {
        return new AcceptanceCriteria(criteria);
    }));

    self.add = function() {
        self.criterias.push(new AcceptanceCriteria());
    };

    self.remove = function(criteria) {
        self.criterias.remove(criteria);
    };
}

function AcceptanceCriteria(data)
{
    var self = this;
    self.id = data.id;
    self.title = data.title;
    self._destroy = false;
}

function remove_fields(link) {
    console.log('123');
    $(link).prev("input[type=hidden]").val("1");
    $(link).closest(".fields").hide();
}

function add_fields(link, association, content) {
    console.log(link);
    console.log(association);
    console.log(content);

    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g")
    $(link).parent().before(content.replace(regexp, new_id));
}